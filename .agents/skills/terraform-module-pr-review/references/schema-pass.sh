#!/bin/bash
# schema-pass.sh: resolves provider versions per module directory and renders provider
# fact sheets from a schema mirror. See schema-pass.md for the inputs, the layout and the
# reason codes. Usage: schema-pass.sh <facts output directory> <work directory>
# Environment: SCHEMA_PROVIDERS, SCHEMA_TYPES (the gate's tokens), MODULESTF_SCHEMA_MIRROR.
# Nothing downloaded is run. Every body is size-checked before any parser reads it.
set -uo pipefail
set -f

OUT="${1:?facts output directory}"
WORK="${2:?work directory}"
HERE="$(cd "$(dirname "$0")" && pwd -P)"
FACTS_JQ="$HERE/schema-facts.jq"
: "${SCHEMA_PROVIDERS=}" "${SCHEMA_TYPES=}" "${MODULESTF_SCHEMA_MIRROR=}"

MAX_PROVIDERS=32
MAX_PROVIDER_VERSIONS=96
MAX_TYPES=1000
CAP_SUMS=4096
CAP_MANIFEST=16384
CAP_VERSIONS=2097152
CAP_GZ=8388608
CAP_SCHEMA=134217728
MIRROR_HOSTS="github.com objects.githubusercontent.com release-assets.githubusercontent.com"
REGISTRY_HOSTS="registry.terraform.io"

rev_re='^(head|base)$'
name_re='^[a-z0-9][a-z0-9-]{0,63}$'
local_re='^[A-Za-z][A-Za-z0-9_-]{0,63}$'
ver_re='^[0-9]{1,5}\.[0-9]{1,5}\.[0-9]{1,5}$'
type_re='^[a-z][a-z0-9_]{0,127}$'
dir_re='^(\.|[A-Za-z0-9._-]{1,64}(/[A-Za-z0-9._-]{1,64}){0,7})$'
con_re='^[0-9A-Za-z.,<>=~! -]{0,64}$'
mirror_re='^[A-Za-z0-9][A-Za-z0-9-]{0,38}/[A-Za-z0-9_][A-Za-z0-9._-]{0,99}$'
reason_re='^(not_in_mirror|network|http_error|rate_limited|host_rejected|redirect_limit|cap_exceeded|schema_too_large|checksum|manifest|json_shape|constraint_unparsable|constraint_unsatisfiable|registry_host|overflow)$'

mkdir -p "$WORK" && [ -z "$(ls -A "$WORK")" ] && mkdir "$WORK/stage" "$WORK/dl" || { echo "schema pass: the work directory is not empty"; exit 1; }
[ ! -e "$OUT" ] && mkdir -p "$OUT" || { echo "schema pass: the output directory already exists"; exit 1; }
: > "$WORK/reasons"
note() { [[ "$1" =~ $reason_re ]] && echo "$1" >> "$WORK/reasons"; } # reason code only

dir_ok() { # directory -> status 0 when it matches the pattern and has no . or .. segment
  [[ "$1" =~ $dir_re ]] || return 1
  [ "$1" = . ] && return 0
  case "/$1/" in */./* | */../*) return 1 ;; esac
}

# One HTTPS request at a time, redirects followed by hand: each Location is checked
# against the host list before the next request. No credential, no -L, no URL from a
# body. Prints a reason code and returns 1 on failure.
fetch() { # url, output file, byte cap, allowed hosts
  local url="$1" out="$2" cap="$3" hosts="$4" hop=0 try code rc host loc last
  while :; do
    [[ "$url" =~ ^https://([^/?#@:[:space:]]+)(/[^#[:space:]]*)?$ ]] || { echo host_rejected; return 1; }
    host="${BASH_REMATCH[1],,}"
    [[ " $hosts " == *" $host "* ]] || { echo host_rejected; return 1; }
    last=network
    for try in 1 2 3; do
      rm -f "$out" "$out.h"
      code="$(curl -s --proto '=https' --tlsv1.2 --max-redirs 0 --connect-timeout 10 --max-time 120 \
        --max-filesize "$cap" -D "$out.h" -o "$out" -w '%{http_code}' -- "$url" 2> /dev/null)"
      rc=$?
      [ "$rc" = 63 ] && { rm -f "$out" "$out.h"; echo cap_exceeded; return 1; }
      if [ "$rc" = 0 ]; then
        case "$code" in
          2?? | 30[12378] | 404) last=""; break ;;
          403 | 429) last=rate_limited ;;
          5??) last=http_error ;;
          *) rm -f "$out" "$out.h"; echo http_error; return 1 ;;
        esac
      else
        last=network
      fi
      [ "$try" = 3 ] || sleep "$try"
    done
    [ -z "$last" ] || { rm -f "$out" "$out.h"; echo "$last"; return 1; }
    if [ "$code" = 404 ]; then rm -f "$out" "$out.h"; echo not_found; return 1; fi
    if [[ "$code" == 2?? ]]; then
      rm -f "$out.h"
      [ -f "$out" ] && [ "$(wc -c < "$out")" -le "$cap" ] || { rm -f "$out"; echo cap_exceeded; return 1; }
      return 0
    fi
    # A redirect: its body is not read; the next URL is its checked Location.
    rm -f "$out"
    hop=$((hop + 1))
    [ "$hop" -le 3 ] || { rm -f "$out.h"; echo redirect_limit; return 1; }
    loc="$(awk 'tolower($0) ~ /^location:/ { sub(/^[^:]*:[ \t]*/, ""); sub(/\r$/, ""); l = $0 } END { print l }' "$out.h")"
    rm -f "$out.h"
    case "$loc" in
      https://*) url="$loc" ;;
      *://* | //* | "") echo host_rejected; return 1 ;;
      /*) url="https://$host$loc" ;;
      *) url="${url%%\?*}"; url="${url%/*}/$loc" ;;
    esac
  done
}

# Versions as integers, so comparisons are numeric per segment.
vnum() { echo $(( 10#$1 * 10000000000 + 10#$2 * 100000 + 10#$3 )); } # major, minor, patch

# A constraint as clauses "<op> <number>", one per line; status 1 when unparsable.
# Terraform's operators: = != > >= < <= ~>, a bare version is =, a comma is AND, a
# partial version is padded with zeros. ~> x.y is >= x.y.0, < (x+1).0.0; ~> x.y.z is
# >= x.y.z, < x.(y+1).0; ~> x is >= x.0.0, < (x+1).0.0.
clauses() { # constraint
  local c="${1// /}" part op a b p
  [ -z "$c" ] && return 0
  [[ "$c" =~ ^[0-9.,\<\>=~!]+$ && ! "$c" =~ (^,|,,|,$) ]] || return 1
  local IFS=,
  for part in $c; do
    [[ "$part" =~ ^(=|!=|>=|<=|>|<|~>)?([0-9]{1,5})(\.([0-9]{1,5}))?(\.([0-9]{1,5}))?$ ]] || return 1
    op="${BASH_REMATCH[1]:-=}" a="${BASH_REMATCH[2]}" b="${BASH_REMATCH[4]}" p="${BASH_REMATCH[6]}"
    if [ "$op" = "~>" ]; then
      echo ">= $(vnum "$a" "${b:-0}" "${p:-0}")"
      if [ -n "$p" ]; then echo "< $(vnum "$a" $((10#$b + 1)) 0)"; else echo "< $(vnum $((10#$a + 1)) 0 0)"; fi
    else
      echo "$op $(vnum "$a" "${b:-0}" "${p:-0}")"
    fi
  done
}

# The candidates, "<number> <x.y.z>" sorted ascending, filtered by the clauses file.
satisfying() { # clauses file, candidates file
  awk 'FILENAME == ARGV[1] { op[++n] = $1; v[n] = $2; next }
    { ok = 1
      for (i = 1; i <= n; i++) {
        if (op[i] == "=" && !($1 == v[i])) ok = 0
        if (op[i] == "!=" && !($1 != v[i])) ok = 0
        if (op[i] == ">" && !($1 > v[i])) ok = 0
        if (op[i] == ">=" && !($1 >= v[i])) ok = 0
        if (op[i] == "<" && !($1 < v[i])) ok = 0
        if (op[i] == "<=" && !($1 <= v[i])) ok = 0
      }
      if (ok) print }' "$1" "$2"
}
has_lower() { grep -qE '^(=|>=|>) ' "$1"; } # clauses file

# 1. The gate's tokens, each checked again here.
: > "$WORK/ptok"
: > "$WORK/unres"
for t in $SCHEMA_PROVIDERS; do
  IFS=: read -r rev dir rest <<< "$t"
  [[ "$rev" =~ $rev_re ]] && dir_ok "$dir" || continue
  if [[ "$rest" =~ ^!(constraint_unparsable)$ ]]; then
    echo "$rev $dir ${BASH_REMATCH[1]}" >> "$WORK/unres"; continue
  fi
  lp="${rest%%:*}" con="${rest#*:}"
  [ "$lp" != "$rest" ] || con=""
  loc="${lp%%=*}" src="${lp#*=}"
  [[ "$loc" =~ $local_re ]] || continue
  [[ "$con" =~ $con_re ]] || con="*" # outside the charset: kept, so it resolves as unparsable
  if [ "$src" = "!registry_host" ]; then echo "$rev $dir !$loc registry_host" >> "$WORK/unres"; continue; fi
  ns="${src%%/*}" name="${src#*/}"
  [[ "$ns" =~ $name_re && "$name" =~ $name_re ]] || continue
  echo "$rev|$dir|$ns/$name|${con// /}" >> "$WORK/ptok"
done
: > "$WORK/types"
for t in $SCHEMA_TYPES; do
  IFS=: read -r dir kind type src extra <<< "$t"
  [ -z "${extra:-}" ] && dir_ok "$dir" && [[ "$kind" =~ ^(resource|data)$ && "$type" =~ $type_re ]] || continue
  ns="${src%%/*}" name="${src#*/}"
  [[ "$ns" =~ $name_re && "$name" =~ $name_re ]] || continue
  echo "$dir $ns/$name $kind $type" >> "$WORK/types"
done
sort -u -o "$WORK/types" "$WORK/types"

# 2. The directory and provider pairs: every head provider token and every provider a
# head type is bound to. A provider with no head token is unconstrained.
{ awk -F'|' '$1 == "head" { print $2, $3 }' "$WORK/ptok"; awk '{ print $1, $2 }' "$WORK/types"; } | sort -u > "$WORK/pairs"
# Providers ranked by their count of needed types, most first, then by name.
awk '{ print $2 }' "$WORK/pairs" | sort -u > "$WORK/provs"
awk 'FNR == NR { n[$2 " " $3 " " $4]++; next } { c = 0; for (k in n) if (index(k, $1 " ") == 1) c++; print c, $1 }' \
  "$WORK/types" "$WORK/provs" | sort -k1,1nr -k2,2 | awk '{ print $2 }' > "$WORK/order"

# 3. The versions: one registry list per provider, stable x.y.z only.
: > "$WORK/resolved"
: > "$WORK/pv"
np=0
while read -r -u 3 prov; do
  np=$((np + 1))
  ns="${prov%%/*}" name="${prov#*/}"
  cand="$WORK/cand-$ns-$name"
  if [ "$np" -gt "$MAX_PROVIDERS" ]; then
    vreason=overflow
  elif r="$(fetch "https://registry.terraform.io/v1/providers/$ns/$name/versions" "$WORK/dl/versions.json" "$CAP_VERSIONS" "$REGISTRY_HOSTS")"; then
    vreason=""
    if jq -r '.versions | if type == "array" then .[] | .version? | strings else error("shape") end' "$WORK/dl/versions.json" > "$WORK/vlist" 2> /dev/null; then
      grep -E "$ver_re" "$WORK/vlist" | awk -F. '{ printf "%.0f %s\n", $1 * 10000000000 + $2 * 100000 + $3, $0 }' | sort -n -u -k1,1 > "$cand"
      [ -s "$cand" ] || vreason=constraint_unsatisfiable
    else
      vreason=json_shape
    fi
  else
    [ "$r" = not_found ] && r=http_error
    vreason="$r"
  fi
  rm -f "$WORK/dl/versions.json"
  while read -r -u 4 dir p; do
    [ "$p" = "$prov" ] || continue
    u="$(awk -v d="$dir" '$1 == "head" && $2 == d && NF == 3 { print $3; exit }' "$WORK/unres")"
    if [ -n "$u" ]; then note "$u"; echo "$dir $prov unresolved $u" >> "$WORK/resolved"; continue; fi
    [ -z "$vreason" ] || { note "$vreason"; echo "$dir $prov unresolved $vreason" >> "$WORK/resolved"; continue; }
    hc="$(awk -F'|' -v d="$dir" -v p="$prov" '$1 == "head" && $2 == d && $3 == p && $4 != "" { printf "%s%s", s, $4; s = "," }' "$WORK/ptok")"
    bc="$(awk -F'|' -v d="$dir" -v p="$prov" '$1 == "base" && $2 == d && $3 == p && $4 != "" { printf "%s%s", s, $4; s = "," }' "$WORK/ptok")"
    if ! clauses "$hc" > "$WORK/hcl"; then note constraint_unparsable; echo "$dir $prov unresolved constraint_unparsable" >> "$WORK/resolved"; continue; fi
    satisfying "$WORK/hcl" "$cand" > "$WORK/sat"
    [ -s "$WORK/sat" ] || { note constraint_unsatisfiable; echo "$dir $prov unresolved constraint_unsatisfiable" >> "$WORK/resolved"; continue; }
    latest="$(tail -n 1 "$WORK/sat" | cut -d ' ' -f 2)" min=- floor=-
    has_lower "$WORK/hcl" && min="$(head -n 1 "$WORK/sat" | cut -d ' ' -f 2)"
    # The old floor, from the base: a base constraint that cannot be read or satisfied
    # is recorded as old_floor_unresolved, never dropped.
    freason=-
    if awk -v d="$dir" '$1 == "base" && $2 == d && NF == 3 { f = 1 } END { exit !f }' "$WORK/unres"; then
      freason=constraint_unparsable
    elif awk -F'|' -v d="$dir" -v p="$prov" '$1 == "base" && $2 == d && $3 == p { f = 1 } END { exit !f }' "$WORK/ptok"; then
      if ! clauses "$bc" > "$WORK/bcl"; then
        freason=constraint_unparsable
      elif has_lower "$WORK/bcl"; then
        f="$(satisfying "$WORK/bcl" "$cand" | head -n 1 | cut -d ' ' -f 2)"
        if [ -z "$f" ]; then freason=constraint_unsatisfiable; elif [ "$f" != "$min" ]; then floor="$f"; fi
      fi
    fi
    [ "$freason" = - ] || note "$freason"
    echo "$dir $prov ok $latest $min $floor $freason" >> "$WORK/resolved"
  done 4< "$WORK/pairs"
done 3< "$WORK/order"

# The provider versions to read, in provider order: latest, minimum, then old floor.
while read -r prov; do
  for col in 4 5 6; do
    awk -v p="$prov" -v c="$col" '$2 == p && $3 == "ok" && $c != "-" { print p, $c }' "$WORK/resolved"
  done
done < "$WORK/order" | awk '!seen[$0]++' > "$WORK/pv-all"
awk -v m="$MAX_PROVIDER_VERSIONS" 'NR <= m' "$WORK/pv-all" > "$WORK/pv"
[ "$(wc -l < "$WORK/pv-all")" -le "$MAX_PROVIDER_VERSIONS" ] || note overflow

# The needed types, in name order, capped; a type past the cap is overflow.
awk '{ print $2, $3, $4 }' "$WORK/types" | sort -u -k3,3 -k2,2 -k1,1 > "$WORK/tall"
awk -v m="$MAX_TYPES" 'NR <= m' "$WORK/tall" > "$WORK/tkeep"
[ "$(wc -l < "$WORK/tall")" -le "$MAX_TYPES" ] || note overflow

# 4. Each provider version: download, check, render, all in its own staging directory.
: > "$WORK/pvok"
: > "$WORK/status"
if [[ -n "$MODULESTF_SCHEMA_MIRROR" && ! "$MODULESTF_SCHEMA_MIRROR" =~ $mirror_re ]]; then
  echo "schema pass: MODULESTF_SCHEMA_MIRROR is not owner/name; no mirror"
  MODULESTF_SCHEMA_MIRROR=""
fi
while read -r -u 3 prov ver; do
  [ -n "$MODULESTF_SCHEMA_MIRROR" ] || break
  ns="${prov%%/*}" name="${prov#*/}"
  [[ "$ver" =~ $ver_re ]] || continue
  d="$WORK/dl" st="$WORK/stage/$ns/$name/$ver"
  rm -rf "$d" && mkdir -p "$d" "$st" || exit 1
  sf="${ns}_${name}-${ver}.schema.json.gz"
  base="https://github.com/$MODULESTF_SCHEMA_MIRROR/releases/download/${ns}_${name}-v${ver}"
  bad=""
  for a in "SHA256SUMS $CAP_SUMS" "manifest.json $CAP_MANIFEST" "$sf $CAP_GZ"; do
    f="${a% *}" cap="${a#* }"
    if ! r="$(fetch "$base/$f" "$d/$f" "$cap" "$MIRROR_HOSTS")"; then
      case "$r" in not_found) r=not_in_mirror ;; cap_exceeded) [ "$f" = "$sf" ] && r=schema_too_large ;; esac
      bad="$r"; break
    fi
  done
  if [ -z "$bad" ]; then
    # The exact lines for the schema and the manifest, each once, checked by sha256sum.
    : > "$d/sums"
    for f in "$sf" manifest.json; do
      n="$(awk -v a="$f" '{ x = $0; sub(/^[^ ]* [ *]?/, "", x); if (x == a) c++ } END { print c + 0 }' "$d/SHA256SUMS")"
      l="$(grep -xE "[0-9a-f]{64}  $(printf '%s' "$f" | sed 's/[.]/\\./g')" "$d/SHA256SUMS")"
      [ "$n" = 1 ] && [ "$(printf '%s\n' "$l" | grep -c .)" = 1 ] && printf '%s\n' "$l" >> "$d/sums" || bad=checksum
    done
    [ -n "$bad" ] || (cd "$d" && sha256sum --strict --quiet -c sums > /dev/null 2>&1) || bad=checksum
  fi
  if [ -z "$bad" ]; then
    jq -e --arg p "$prov" --arg v "$ver" --arg f "$sf" 'type == "object" and .provider == $p and .version == $v and .file == $f
      and (.format_version | type == "string" and test("^([0-9]+)\\.[0-9]+$") and (split(".")[0] == "1"))' \
      "$d/manifest.json" > /dev/null 2>&1 || bad=manifest
  fi
  if [ -z "$bad" ]; then
    gzip -dc -- "$d/$sf" 2> /dev/null | head -c $((CAP_SCHEMA + 1)) > "$d/schema.json"
    [ "${PIPESTATUS[0]}" = 0 ] && [ "$(wc -c < "$d/schema.json")" -le "$CAP_SCHEMA" ] || bad=schema_too_large
  fi
  if [ -z "$bad" ]; then
    jq -e --arg k "registry.terraform.io/$prov" '(.format_version | type == "string" and test("^([0-9]+)\\.[0-9]+$") and (split(".")[0] == "1"))
      and (.provider_schemas | type == "object" and keys == [$k])' "$d/schema.json" > /dev/null 2>&1 || bad=json_shape
  fi
  if [ -z "$bad" ]; then
    # The types this provider version is needed for, as JSON arguments; never program text.
    want="$(awk -v p="$prov" '$1 == p { print $2, $3 }' "$WORK/tkeep" | jq -R -c -s 'split("\n") | map(select(. != "") | split(" "))')"
    sha="$(sha256sum -- "$d/$sf" | cut -d ' ' -f 1)"
    head="$(jq -n -c --arg p "$prov" --arg v "$ver" --arg s "$sha" '{provider: $p, version: $v, schema_sha256: $s}')"
    if jq -r --arg key "registry.terraform.io/$prov" --argjson want "$want" --argjson head "$head" -f "$FACTS_JQ" \
      "$d/schema.json" > "$d/rendered" 2> /dev/null; then
      mkdir -p "$st/resources" "$st/data-sources"
      : > "$d/index"
      while read -r kind type status b64; do
        [[ "$kind" =~ ^(resource|data)$ && "$type" =~ $type_re && "$status" =~ ^(sheet|absent|miss)$ ]] || { bad=json_shape; break; }
        cat=resources; [ "$kind" = data ] && cat=data-sources
        if [ "$status" = sheet ]; then
          printf '%s' "$b64" | base64 -d > "$st/$cat/$type.facts" 2> /dev/null || { bad=json_shape; break; }
        fi
        [ "$status" = miss ] && status=page
        echo "$kind:$type $status" >> "$d/index"
      done < "$d/rendered"
      [ -n "$bad" ] || jq -R -s -c --arg p "$prov" --arg v "$ver" --arg s "$sha" \
        '{provider: $p, version: $v, schema_sha256: $s, types: (split("\n") | map(select(. != "") | split(" ") | {(.[0]): .[1]}) | add // {})}' \
        "$d/index" > "$st/index.json" || bad=json_shape
    else
      bad=json_shape
    fi
  fi
  if [ -n "$bad" ]; then
    note "$bad"
    rm -rf "$st"
  else
    echo "$prov $ver" >> "$WORK/pvok"
    jq -r --arg p "$prov" --arg v "$ver" '.types | to_entries[] | "\($p) \($v) \(.key | sub(":"; " ")) \(.value)"' "$st/index.json" >> "$WORK/status"
  fi
done 3< "$WORK/pv"
rm -rf "$WORK/dl"

# 5. Same source per type: a type is read from sheets only when every version it is
# needed at is a sheet or absent; otherwise it is page at every version.
awk 'FILENAME == ARGV[1] { st[$1 " " $2 " " $3 " " $4] = $5; next }
  FILENAME == ARGV[2] { res[$1 " " $2] = $3 " " $4 " " $5 " " $6; next }
  FILENAME == ARGV[3] { keep[$0] = 1; next }
  FILENAME == ARGV[4] { use[$2 " " $3 " " $4] = use[$2 " " $3 " " $4] " " $1; next }
  { k = $1 " " $2 " " $3; page = !(k in keep)
    n = split(use[k], ds, " ")
    for (i = 1; i <= n && !page; i++) {
      split(res[ds[i] " " $1], r, " ")
      if (r[1] != "ok") { page = 1; break }
      for (j = 2; j <= 4; j++) {
        if (r[j] == "-") continue
        s = st[$1 " " r[j] " " $2 " " $3]
        if (s != "sheet" && s != "absent") { page = 1; break }
      }
    }
    if (page) print k }' "$WORK/status" "$WORK/resolved" "$WORK/tkeep" "$WORK/types" "$WORK/tall" > "$WORK/pagetypes"
while read -r -u 3 prov ver; do
  ns="${prov%%/*}" name="${prov#*/}" st="$WORK/stage/$ns/$name/$ver"
  keys="$(awk -v p="$prov" '$1 == p { print $2 ":" $3 }' "$WORK/pagetypes" | jq -R -s -c 'split("\n") | map(select(. != ""))')"
  jq -c --argjson ks "$keys" '.types |= with_entries(if (.key | IN($ks[])) then .value = "page" else . end)' "$st/index.json" > "$st/index.n" &&
    mv "$st/index.n" "$st/index.json" || exit 1
  awk -v p="$prov" '$1 == p { print ($2 == "data" ? "data-sources" : "resources") "/" $3 ".facts" }' "$WORK/pagetypes" |
    while IFS= read -r f; do rm -f "$st/$f"; done
  rmdir "$st/resources" "$st/data-sources" 2> /dev/null
done 3< "$WORK/pvok"

# The pages the host prefetches into the page cache: every needed version of a page type,
# and the latest version of every other type, for the rules that need page facts.
: > "$WORK/wanted-pages"
while read -r dir prov st latest min floor _; do
  [ "$st" = ok ] || continue
  ns="${prov%%/*}" name="${prov#*/}"
  awk -v d="$dir" -v p="$prov" '$1 == d && $2 == p { print $3, $4 }' "$WORK/types" | while read -r kind type; do
    [[ "$type" == "${name}_"* ]] || continue
    cat=resources; [ "$kind" = data ] && cat=data-sources
    vs="$latest"
    grep -qxF "$prov $kind $type" "$WORK/pagetypes" && vs="$latest $min $floor"
    for v in $vs; do
      [ "$v" = - ] || echo "$ns/$name/$v/$cat/${type#"${name}_"}.md"
    done
  done
done < "$WORK/resolved" >> "$WORK/wanted-pages"
sort -u -o "$WORK/wanted-pages" "$WORK/wanted-pages"

# 6. Publish: each staged provider version moves whole; then versions.json; then the
# checksums, last.
while read -r prov ver; do
  ns="${prov%%/*}" name="${prov#*/}"
  mkdir -p "$OUT/$ns/$name" && mv "$WORK/stage/$ns/$name/$ver" "$OUT/$ns/$name/$ver" || exit 1
done < "$WORK/pvok"
{
  awk '{ print $1, $2, $3, $4, $5, $6, ($7 == "" ? "-" : $7) }' "$WORK/resolved"
  awk '$1 == "head" && NF == 4 { print $2, $3, "unresolved", $4 }' "$WORK/unres"
} | jq -R -s -c '
  split("\n") | map(select(. != "") | split(" "))
  | reduce .[] as $r ({};
      .[$r[0]][$r[1]] = (if $r[2] == "ok"
        then {latest: $r[3]} + (if $r[4] != "-" then {minimum: $r[4]} else {} end) + (if $r[5] != "-" then {old_floor: $r[5]} else {} end)
          + (if $r[6] != "-" then {old_floor_unresolved: $r[6]} else {} end)
        else {unresolved: $r[3]} end))
  | {format: 1, directories: .}' > "$OUT/versions.json" || exit 1
(cd "$OUT" && find . -type f ! -path ./files.sha256 -printf '%P\n' | LC_ALL=C sort | while IFS= read -r f; do sha256sum -- "$f"; done) > "$WORK/files.sha256" &&
  mv "$WORK/files.sha256" "$OUT/files.sha256" || exit 1

echo "schema pass: $(wc -l < "$WORK/pvok") of $(wc -l < "$WORK/pv") provider versions read, $(grep -c . "$WORK/pagetypes") page types"
sort "$WORK/reasons" | uniq -c | awk '{ print "schema pass reason: " $2 " " $1 }'
exit 0

#!/bin/bash
# Smoke test of the isolated plan runner. Needs a local Docker runtime and network access
# for the image builds; uses no AWS account and no real credentials.
#
# It plans smoke/example with made-up session credentials and probes the network after
# each phase. Success means:
# - init reaches the registry and download hosts, and not AWS;
# - plan reaches STS through the plan-phase proxy and STS rejects the made-up key
#   (InvalidClientTokenId), which proves the path to AWS without any real credential;
# - during plan the registry, GitHub, EC2 public DNS names and S3 bucket hosts are refused;
# - a direct connection that bypasses the proxy fails, and outside names do not resolve;
# - plain HTTP through the proxy is refused;
# - credentials without a session token are refused before anything starts;
# - an oversized file in the output directory is refused;
# - with --base, only the example whose plan is a code-error is re-run at the merge base;
# - the image tag is derived from the image files unless PLAN_RUNNER_TAG sets it;
# - no container, network or volume of these runs is left behind.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
rec="$(mktemp -d "${TMPDIR:-/tmp}/plan-runner-smoke.XXXXXX")"
creds="$rec/fake-credentials.env"
printf '%s\n' AWS_ACCESS_KEY_ID=smoke-test-not-a-key AWS_SECRET_ACCESS_KEY=smoke-test-not-a-secret \
  AWS_SESSION_TOKEN=smoke-test-not-a-token > "$creds"
static="$rec/static-credentials.env"
printf '%s\n' AWS_ACCESS_KEY_ID=smoke-test-not-a-key AWS_SECRET_ACCESS_KEY=smoke-test-not-a-secret > "$static"

"$here/run-plan.sh" --build --probe --clone "$here/smoke" --example example \
  --record "$rec/record" --credentials-env-file "$creds" > /dev/null
"$here/run-plan.sh" --clone "$here/smoke" --example example \
  --record "$rec/static" --credentials-env-file "$static" > "$rec/static.out" 2>&1
static_rc=$?
"$here/run-plan.sh" --clone "$here/smoke" --example attack --record "$rec/attack" \
  > "$rec/attack.out" 2>&1
attack_rc=$?

fails=0
check() { # description, command...
  local d="$1"; shift
  if "$@" > /dev/null 2>&1; then echo "ok   $d"; else echo "FAIL $d"; fails=$((fails + 1)); fi
}
r="$rec/record"
check "init succeeded" grep -qx 'init 0' "$r/status"
check "init downloaded the provider through the proxy" grep -q 'CONNECT releases.hashicorp.com:443' "$r/proxy-init.log"
check "init phase refuses AWS" grep -qx 'proxy sts.us-east-1.amazonaws.com: refused' "$r/probe-init.log"
check "init phase passes GitHub" grep -q '^proxy github.com: passed' "$r/probe-init.log"
check "plan reached STS through the plan proxy" grep -q 'CONNECT sts\.[a-z0-9-]*\.amazonaws\.com:443' "$r/proxy-plan.log"
check "STS rejected the made-up key" grep -q 'InvalidClientTokenId' "$r/plan.log"
check "plan phase refuses the registry" grep -qx 'proxy registry.terraform.io: refused' "$r/probe-plan.log"
check "plan phase refuses GitHub" grep -qx 'proxy github.com: refused' "$r/probe-plan.log"
check "plan phase refuses an EC2 public DNS name" grep -qx 'proxy ec2-192-0-2-1.compute-1.amazonaws.com: refused' "$r/probe-plan.log"
check "plan phase refuses an S3 bucket host" grep -qx 'proxy probe-bucket.s3.amazonaws.com: refused' "$r/probe-plan.log"
check "plan phase refuses a regional S3 bucket host" grep -qx 'proxy probe-bucket.s3.us-east-1.amazonaws.com: refused' "$r/probe-plan.log"
check "plan phase refuses a host outside AWS" grep -qx 'proxy example.com: refused' "$r/probe-plan.log"
check "refused plan hosts are listed" grep -qx 'github.com:443' "$r/plan-refused-hosts.txt"
check "plan phase refuses a CONNECT to port 8443" grep -qx 'proxy sts.us-east-1.amazonaws.com:8443: refused' "$r/probe-plan.log"
check "the port 8443 attempt is listed" grep -qx 'sts.us-east-1.amazonaws.com:8443' "$r/plan-refused-hosts.txt"
for phase in init plan; do
  check "$phase: direct connection to an address fails" grep -qx 'direct 1.1.1.1:443: closed' "$r/probe-$phase.log"
  check "$phase: direct connection to an allowed host fails" grep -qx 'direct registry.terraform.io:443: closed' "$r/probe-$phase.log"
  check "$phase: outside names do not resolve" grep -qx 'dns example.com: does not resolve' "$r/probe-$phase.log"
  check "$phase: plain HTTP through the proxy is refused" grep -qx 'proxy plain-http registry.terraform.io: exit 0 http 403' "$r/probe-$phase.log"
done
check "credentials without a session token are refused" test "$static_rc" -eq 2
check "the refusal says why" grep -q 'no session token' "$rec/static.out"
a="$rec/attack"
check "attack: the run completed" test "$attack_rc" -eq 0
check "attack: the planted status link was refused" grep -qx 'not a regular file in the work volume, not exported: out/status' "$a/export-refused.txt"
check "attack: the planted plan.log link was refused" grep -qx 'not a regular file in the work volume, not exported: out/plan.log' "$a/export-refused.txt"
check "attack: the record holds no link" test -z "$(find "$a" "$r" -type l -print -quit)"
check "attack: the record holds no password-file content" test -z "$(grep -rl -e 'root:' -e 'User Database' "$a" 2>/dev/null)"
check "attack: the unlisted planted name was not exported" test ! -e "$a/extra"
check "attack: an oversized file was refused" grep -qx 'larger than 5242880 bytes, not exported: out/probe-init.log' "$a/export-refused.txt"
check "attack: the oversized file is not in the record" test ! -e "$a/probe-init.log"
# The plan pass in the runner, on a git fixture holding both smoke examples and one whose init
# fails the same way at the head and at the merge base: a code-error that needs no credentials.
# The fixture is its own origin, so the base fetch stays inside the work volume. The made-up
# credentials fail the pass's sts check, so the pass ends at credentials after init. Ten more
# copies of the failing example make thirteen, past the laptop's cap of twelve, which the
# runner does not have.
repo="$rec/pass-repo"
mkdir -p "$repo/examples/broken"
printf 'terraform {\n  required_version = "= 0.0.1"\n}\n' > "$repo/examples/broken/main.tf"
git -C "$repo" init -q
git -C "$repo" remote add origin .
git -C "$repo" add -A
git -C "$repo" -c user.name=smoke -c user.email=smoke@example.com commit -q -m base
basesha="$(git -C "$repo" rev-parse HEAD)"
cp -R "$here/smoke/example" "$repo/examples/sts"
cp -R "$here/smoke/attack" "$repo/examples/attack"
git -C "$repo" add -A
git -C "$repo" -c user.name=smoke -c user.email=smoke@example.com commit -q -m head
mkdir -m 0700 "$rec/pass-tmp"
"$here/run-pass.sh" --clone "$repo" --record "$rec/pass" --tmp "$rec/pass-tmp" --credentials-env-file "$creds" \
  --base "$basesha" examples/broken examples/sts examples/attack examples/broken examples/broken \
  examples/broken examples/broken examples/broken examples/broken examples/broken examples/broken \
  examples/broken examples/broken > /dev/null 2> "$rec/pass.err"
p="$rec/pass"
check "pass: init phase readied both examples" grep -qx 'init: examples/attack: ready' "$p/plan-pass-init.txt"
check "pass: plan phase checked the credentials through the plan proxy" grep -q 'CONNECT sts\.[a-z0-9-]*\.amazonaws\.com:443' "$p/proxy-plan.log"
check "pass: made-up credentials end the pass" grep -qx 'plan: plan pass ended: credentials' "$p/plan-pass.txt"
check "pass: the host heads each example's block" grep -qx 'host example 2: examples/sts' "$p/plan-pass.txt"
check "pass: the summary line is written" grep -qx 'plan summary: 13 examples, 0 planned, 0 exceptions, 13 other' "$p/plan-pass.txt"
check "pass: the budget is recorded" grep -qx 'plan pass budget: 120 minutes' "$p/plan-pass.txt"
check "pass: no example cap in the runner" test "$(grep -c '^init: examples/broken: code-error$' "$p/plan-pass-init.txt")" -eq 11
check "pass: only the code-error was prepared at the base" test "$(grep -c ' at base: ' "$p/plan-pass-init.txt")" -eq 1
check "pass: the code-error was initialised at the base" grep -qx 'init: examples/broken at base: code-error' "$p/plan-pass-init.txt"
check "pass: the deferred base line was filled in" grep -qx 'base: reproduces at base' "$p/plan-pass.txt"
check "pass: no deferred base line is left" test -z "$(grep -x 'base: deferred' "$p/plan-pass.txt")"
check "pass: init reached no AWS endpoint" test -z "$(grep 'amazonaws' "$p/proxy-init.log")"
check "pass: no credential value in the record" test -z "$(grep -rl 'smoke-test-not-a-' "$p")"
check "pass: the record holds regular files only" test -z "$(find "$p" -mindepth 1 ! -type f -print -quit)"
check "pass: nothing is left under --tmp" test -z "$(find "$rec/pass-tmp" -mindepth 1 -print -quit)"
# --tmp is where the private temporary directory goes: one that cannot be written to stops
# the run before any credential is read or any Docker object is made.
mkdir -m 0500 "$rec/ro-tmp"
"$here/run-pass.sh" --clone "$repo" --record "$rec/ro-pass" --tmp "$rec/ro-tmp" --credentials-env-file "$creds" \
  examples/sts > /dev/null 2>&1
ro_rc=$?
check "pass: an unwritable --tmp stops the run" test "$ro_rc" -ne 0
check "pass: an unwritable --tmp made no Docker object" test ! -e "$rec/ro-pass/run-id.txt"

# The host leak scan, on a crafted record: exact values and every evidence pattern go, an
# ordinary line stays.
s="$rec/scan"
mkdir -p "$s"
{
  echo 'plan: planned | Plan: 1 to add, 0 to change, 0 to destroy.'
  echo 'key AKIAABCDEFGHIJKLMNOP'
  echo 'jwt eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0'
  echo '-----BEGIN PRIVATE KEY-----'
  echo 'url ?X-Amz-Signature=abc'
  echo 'Authorization: AWS4-HMAC-SHA256'
  echo 'encoded c21va2UtdGVzdC1ub3QtYS1zZWNyZXQtdmFsdWUtZW5jb2RlZA=='
  echo 'value smoke-test-exact-value'
  echo 'split smoke-test-exa'
  echo 'ct-value across two lines'
  echo 'id AKIAABCDEF'
  echo '  GHIJKLMNOP split too'
  echo 'scope: examples/sts'
} > "$s/plan-pass.txt"
echo 'smoke-test-exact-value' > "$rec/scan-values"
scanned="$("$here/record-scan.sh" "$s" "$rec/scan-values")"
check "scan: every crafted leak line is removed, split ones included" test "$scanned" -eq 11
check "scan: the line after a split secret stays" grep -qx 'scope: examples/sts' "$s/plan-pass.txt"
check "scan: the ordinary line stays" grep -qx 'plan: planned | Plan: 1 to add, 0 to change, 0 to destroy.' "$s/plan-pass.txt"
check "scan: no crafted secret is left" test -z "$(grep -E 'AKIA|GHIJKLMNOP|eyJ|BEGIN|Signature|Authorization|c21va2|exact-value|smoke-test-exa|ct-value' "$s/plan-pass.txt")"

# The image tag: derived from the image files unless PLAN_RUNNER_TAG is set, and refused
# when it is not a valid tag.
tag1="$(env -u PLAN_RUNNER_TAG "$here/image-tag.sh")"
tag2="$(env -u PLAN_RUNNER_TAG "$here/image-tag.sh")"
check "image tag: the default is src- and 12 hex digits" test -n "$(printf '%s\n' "$tag1" | grep -Ex 'src-[0-9a-f]{12}')"
check "image tag: the default is the same on every call" test "$tag1" = "$tag2"
check "image tag: PLAN_RUNNER_TAG overrides it" test "$(PLAN_RUNNER_TAG=smoke-x "$here/image-tag.sh")" = smoke-x
check "image tag: an invalid PLAN_RUNNER_TAG is refused" test "$(PLAN_RUNNER_TAG='a b' "$here/image-tag.sh" > /dev/null 2>&1; echo $?)" -eq 2

# Leftovers: each run names everything it creates with its own id, recorded in run-id.txt.
# Only those exact names are inspected here; nothing is removed, and no prefix is matched, so
# another run on the same Docker daemon is neither touched nor counted.
leftover() { # ids...: prints each of those runs' containers, networks and volumes still present
  local id n
  for id in "$@"; do
    for n in "plan-runner-$id" "plan-proxy-$id" "plan-proxy-init-$id" "plan-proxy-plan-$id" "plan-export-$id"; do
      docker container inspect "$n" > /dev/null 2>&1 && echo "container $n"
    done
    for n in "plan-int-$id" "plan-ext-$id"; do
      docker network inspect "$n" > /dev/null 2>&1 && echo "network $n"
    done
    docker volume inspect "plan-work-$id" > /dev/null 2>&1 && echo "volume plan-work-$id"
  done
  return 0
}
ids="$(cat "$r/run-id.txt" "$a/run-id.txt" "$rec/static/run-id.txt" "$p/run-id.txt" 2>/dev/null)"
check "every run recorded its id" test "$(printf '%s\n' "$ids" | grep -c .)" -eq 4
# shellcheck disable=SC2086 # one id per word
check "no container, network or volume of these runs left behind" test -z "$(leftover $ids)"

echo "record: $r"
[ "$fails" -eq 0 ] && echo "smoke passed" || echo "smoke failed: $fails"
exit "$fails"

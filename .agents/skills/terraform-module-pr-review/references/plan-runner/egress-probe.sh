#!/bin/bash
# Egress probe for the smoke test. Runs inside the runner container on the internal
# network, after a phase, and records whether each path out is open or closed.
# Usage: egress-probe init|plan
set -uo pipefail

phase="${1:?usage: egress-probe init|plan}"
out=/work/out/probe-$phase.log
mkdir -p /work/out
: > "$out"
line() { printf '%s\n' "$*" >> "$out"; }

# A direct TCP connection, bypassing the proxy, to an address and to an allowed host.
for target in 1.1.1.1:443 registry.terraform.io:443; do
  host="${target%:*}" port="${target##*:}"
  if timeout 5 bash -c "exec 3<>/dev/tcp/$host/$port" 2>/dev/null; then
    line "direct $target: OPEN"
  else
    line "direct $target: closed"
  fi
done

# Name resolution of an outside host, which would be a DNS side channel.
if timeout 5 getent hosts example.com > /dev/null 2>&1; then
  line "dns example.com: resolves"
else
  line "dns example.com: does not resolve"
fi

# A plain HTTP request through the proxy, to an allowed host.
code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 -x "$HTTP_PROXY" http://registry.terraform.io/ 2>/dev/null)
line "proxy plain-http registry.terraform.io: exit $? http ${code:-none}"

# CONNECT through the proxy, one line per host.
for host in example.com registry.terraform.io github.com sts.us-east-1.amazonaws.com \
            ec2-192-0-2-1.compute-1.amazonaws.com probe-bucket.s3.amazonaws.com \
            probe-bucket.s3.us-east-1.amazonaws.com; do
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 -x "$HTTPS_PROXY" "https://$host/" 2>/dev/null)
  rc=$?
  if [ "$rc" -eq 56 ] || [ "$rc" -eq 5 ]; then
    line "proxy $host: refused"
  else
    line "proxy $host: passed (exit $rc http ${code:-none})"
  fi
done

# CONNECT to an allowed host on a port other than 443.
code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 -x "$HTTPS_PROXY" https://sts.us-east-1.amazonaws.com:8443/ 2>/dev/null)
rc=$?
if [ "$rc" -eq 56 ] || [ "$rc" -eq 5 ]; then
  line "proxy sts.us-east-1.amazonaws.com:8443: refused"
else
  line "proxy sts.us-east-1.amazonaws.com:8443: passed (exit $rc http ${code:-none})"
fi
exit 0

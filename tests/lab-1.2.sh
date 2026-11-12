#!/usr/bin/env bash
# Checks every command and output shown in Episode 1.2, plus the lab's plan checker.
# Needs root, iproute2, curl and python3.
#
#   sudo tests/lab-1.2.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LAB="$ROOT/01-networking/1.1-packet-path/packetlab.sh"
CHECK="$ROOT/01-networking/1.2-cidr/subnetcheck.py"
TMP="$(mktemp -d)"
FAILS=0

cleanup() { "$LAB" down >/dev/null 2>&1 || true; rm -rf "$TMP"; }
trap cleanup EXIT

pass() { echo "PASS  $1"; }
fail() { echo "FAIL  $1"; FAILS=$((FAILS + 1)); }
expect() { local desc=$1; shift; if "$@"; then pass "$desc"; else fail "$desc"; fi; }
contains() { [[ "$1" == *"$2"* ]]; }
lacks() { [[ "$1" != *"$2"* ]]; }
is_unanswered() { [[ "$1" == *INCOMPLETE* || "$1" == *FAILED* ]]; }

client() { ip netns exec pl-client "$@"; }
fetch() { client curl --noproxy '*' -s -m 5 -o /dev/null -w '%{http_code}' http://10.0.2.10/ || true; }
py() { python3 -c "import ipaddress as i; $1" 2>&1 || true; }

echo "== Python cards"
expect "10.0.1.10 is 167772426 and its 32 bits" \
  contains "$(py "a=i.ip_address('10.0.1.10'); print(int(a), format(int(a),'032b'))")" \
  "167772426 00001010000000000000000100001010"
expect "/24 network, mask and size" \
  contains "$(py "n=i.ip_network('10.0.1.10/24', strict=False); print(n, n.netmask, n.num_addresses)")" \
  "10.0.1.0/24 255.255.255.0 256"
out=$(py "print(list(i.ip_network('10.0.0.0/16').subnets(prefixlen_diff=1))); i.ip_network('10.0.1.0/23')")
expect "a /16 splits into two /17 halves" \
  contains "$out" "[IPv4Network('10.0.0.0/17'), IPv4Network('10.0.128.0/17')]"
expect "10.0.1.0/23 is rejected" contains "$out" "ValueError: 10.0.1.0/23 has host bits set"
out=$(py "[print(n) for n in i.ip_network('10.0.0.0/16').subnets(new_prefix=20)]")
expect "a /16 holds sixteen /20 blocks" [ "$(echo "$out" | wc -l)" -eq 16 ]
expect "the last /20 is 10.0.240.0/20" contains "$out" "10.0.240.0/20"

echo "== starting the 1.1 lab"
"$LAB" up >/dev/null

echo "== /24: different network, so via the router"
expect "client has 10.0.1.10/24" contains "$(client ip -br addr show eth0)" "10.0.1.10/24"
expect "10.0.2.10 goes via 10.0.1.1" contains "$(client ip route get 10.0.2.10)" "via 10.0.1.1"
expect "the page loads" [ "$(fetch)" = "200" ]

echo "== longest prefix wins"
expect "10.0.1.20 goes straight out eth0" lacks "$(client ip route get 10.0.1.20)" "via"
expect "8.8.8.8 goes via the router" contains "$(client ip route get 8.8.8.8)" "via 10.0.1.1"

echo "== /16: 10.0.2.10 looks local and the request dies"
client ip addr del 10.0.1.10/24 dev eth0
client ip addr add 10.0.1.10/16 dev eth0
client ip route add default via 10.0.1.1
expect "10.0.2.10 no longer goes via the router" lacks "$(client ip route get 10.0.2.10)" "via"
expect "the request fails" [ "$(fetch)" != "200" ]
neigh=$(client ip neigh show 10.0.2.10)
echo "   ip neigh: $neigh"
expect "nobody answers the ARP question (INCOMPLETE, or FAILED once it gives up)" \
  is_unanswered "$neigh"

echo "== back to /24: it works again"
client ip addr del 10.0.1.10/16 dev eth0
client ip addr add 10.0.1.10/24 dev eth0
client ip route add default via 10.0.1.1
expect "the page loads again" [ "$(fetch)" = "200" ]

echo "== plan checker"
quiet() { "$@" >/dev/null; }
expect "the sample plan passes all checks" quiet python3 "$CHECK" "$ROOT/01-networking/1.2-cidr/plan-example.txt"
cat >"$TMP/video.txt" <<'EOF'
vpc       10.0.0.0/16
public-a  10.0.0.0/20
public-b  10.0.16.0/20
app-a     10.0.32.0/20
app-b     10.0.48.0/20
data-a    10.0.64.0/20
data-b    10.0.80.0/20
EOF
out=$(python3 "$CHECK" "$TMP/video.txt" || true)
expect "copying the video's plan fails: it overlaps the existing VPC" \
  contains "$out" "FAIL  VPC does not overlap the existing VPC"
cat >"$TMP/bad.txt" <<'EOF'
vpc       10.1.0.0/16
public-a  10.1.0.0/24
public-b  10.1.0.128/25
app-a     10.1.16.0/22
app-b     10.1.32.0/20
data-a    10.1.48.0/24
data-b    10.1.49.0/24
EOF
out=$(python3 "$CHECK" "$TMP/bad.txt" || true)
expect "overlapping subnets are caught" contains "$out" "public-a overlaps public-b"
expect "an app subnet that is too small is caught" contains "$out" "FAIL  app-a has 1019 usable addresses"
printf 'vpc 10.1.0.0/16\npublic-a 10.1.1.0/23\n' >"$TMP/misaligned.txt"
out=$(python3 "$CHECK" "$TMP/misaligned.txt" 2>&1 || true)
expect "a misaligned block is rejected" contains "$out" "has host bits set"

echo
if [ "$FAILS" -eq 0 ]; then echo "All checks passed."; else echo "$FAILS check(s) failed."; exit 1; fi

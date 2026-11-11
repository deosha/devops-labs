#!/usr/bin/env bash
# Runs the Episode 1.1 lab end to end and checks every claim the video makes.
# Needs root, iproute2, tcpdump, curl, iputils-ping and python3.
#
#   sudo tests/lab-1.1.sh
set -euo pipefail

LAB="$(cd "$(dirname "$0")/../01-networking/1.1-packet-path" && pwd)/packetlab.sh"
TMP="$(mktemp -d)"
FAILS=0

cleanup() { "$LAB" down >/dev/null 2>&1 || true; rm -rf "$TMP"; }
trap cleanup EXIT

pass() { echo "PASS  $1"; }
fail() { echo "FAIL  $1"; FAILS=$((FAILS + 1)); }
expect() { local desc=$1; shift; if "$@"; then pass "$desc"; else fail "$desc"; fi; }
contains() { [[ "$1" == *"$2"* ]]; }
in_file() { grep -q -- "$2" "$1"; }

in_ns() { local ns=$1; shift; ip netns exec "pl-$ns" "$@"; }
mac_of() { in_ns "$1" cat "/sys/class/net/$2/address"; }
fetch() { in_ns client curl --noproxy '*' -s -m 5 http://10.0.2.10/index.html; }

echo "== starting the lab"
"$LAB" up

echo "== Part B: the request works"
expect "curl returns the page" contains "$(fetch)" "Hello from the web server at 10.0.2.10"

echo "== Part C: the destination MAC is the router's"
fetch >/dev/null
router_eth0=$(mac_of router eth0)
expect "client's neighbour entry for 10.0.1.1 is the router's eth0 MAC" \
  contains "$(in_ns client ip neigh show 10.0.1.1)" "$router_eth0"

echo "== Part D: routing tables"
expect "client has one default route via the router" \
  contains "$(in_ns client ip route)" "default via 10.0.1.1 dev eth0"
expect "router knows the client network" contains "$(in_ns router ip route)" "10.0.1.0/24 dev eth0"
expect "router knows the web network" contains "$(in_ns router ip route)" "10.0.2.0/24 dev eth1"

echo "== Part D: compare both sides of the router"
for side in eth0 eth1; do
  in_ns router timeout 8 tcpdump -i "$side" -e -nn -v -c 1 'tcp[tcpflags] == tcp-syn' >"$TMP/$side.txt" 2>/dev/null &
done
sleep 2
fetch >/dev/null
wait
a=$(cat "$TMP/eth0.txt")
b=$(cat "$TMP/eth1.txt")
echo "   eth0: $(echo "$a" | head -1 | cut -c1-110)"
echo "   eth1: $(echo "$b" | head -1 | cut -c1-110)"
expect "client side ttl is 64" contains "$a" "ttl 64"
expect "server side ttl is 63" contains "$b" "ttl 63"
expect "client side frame goes client MAC -> router eth0 MAC" \
  contains "$a" "$(mac_of client eth0) > $router_eth0"
expect "server side frame goes router eth1 MAC -> web MAC" \
  contains "$b" "$(mac_of router eth1) > $(mac_of web eth0)"
expect "client side carries 10.0.1.10 -> 10.0.2.10:80" contains "$(echo "$a" | tr '\n' ' ')" " > 10.0.2.10.80"
expect "server side carries the same IP addresses" contains "$(echo "$b" | tr '\n' ' ')" " > 10.0.2.10.80"
expect "source IP unchanged across the router" contains "$(echo "$b" | tr '\n' ' ')" "10.0.1.10."

echo "== Part D: time to live reaching zero"
ping_out=$(in_ns client ping -c 1 -t 1 -W 2 10.0.2.10 2>&1 || true)
expect "ttl-1 ping answered by the router (10.0.1.1)" contains "$ping_out" "From 10.0.1.1"
expect "the answer is 'Time to live exceeded'" contains "$ping_out" "Time to live exceeded"

echo "== Part E: the reply"
in_ns web timeout 8 tcpdump -i eth0 -nn -A -c 12 tcp port 80 >"$TMP/web.txt" 2>/dev/null &
sleep 2
fetch >/dev/null
wait || true
expect "reply travels 10.0.2.10.80 -> client" in_file "$TMP/web.txt" "10.0.2.10.80 > 10.0.1.10"
expect "reply is HTTP 200 OK" in_file "$TMP/web.txt" "200 OK"

echo "== cleanup"
"$LAB" down
no_lab_ns() { ! ip netns list | grep -q "^pl-"; }
expect "all lab namespaces removed" no_lab_ns

echo
if [ "$FAILS" -eq 0 ]; then
  echo "All checks passed."
else
  echo "$FAILS check(s) failed."
  exit 1
fi

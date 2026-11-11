#!/usr/bin/env bash
# packetlab.sh - the network from Episode 1.1 on one Linux machine.
#
#   client 10.0.1.10 --- 10.0.1.1 router 10.0.2.1 --- 10.0.2.10 web
#
# Three network namespaces joined by two virtual cables. Needs root,
# iproute2, python3. tcpdump, curl and ping are used in the exercises.
#
#   sudo ./packetlab.sh up            build the network and start the web server
#   sudo ./packetlab.sh sh client     open a shell "inside" client (or router, web)
#   sudo ./packetlab.sh status        show addresses and MACs of all three
#   sudo ./packetlab.sh down          remove everything
set -euo pipefail

NS=(client router web)
WEBROOT=/tmp/packetlab-web
PIDFILE=/tmp/packetlab-web.pid

need_root() { [ "$(id -u)" -eq 0 ] || { echo "Run with sudo." >&2; exit 1; }; }
in_ns() { local ns=$1; shift; ip netns exec "pl-$ns" "$@"; }

down() {
  [ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null || true
  rm -f "$PIDFILE"
  for n in "${NS[@]}"; do ip netns del "pl-$n" 2>/dev/null || true; done
  rm -rf "$WEBROOT"
}

up() {
  down
  for n in "${NS[@]}"; do ip netns add "pl-$n"; in_ns "$n" ip link set lo up; done

  # cable 1: client eth0 <-> router eth0      cable 2: router eth1 <-> web eth0
  ip link add pl-c0 type veth peer name pl-r0
  ip link add pl-r1 type veth peer name pl-w0
  ip link set pl-c0 netns pl-client name eth0
  ip link set pl-r0 netns pl-router name eth0
  ip link set pl-r1 netns pl-router name eth1
  ip link set pl-w0 netns pl-web name eth0

  in_ns client ip addr add 10.0.1.10/24 dev eth0
  in_ns router ip addr add 10.0.1.1/24 dev eth0
  in_ns router ip addr add 10.0.2.1/24 dev eth1
  in_ns web ip addr add 10.0.2.10/24 dev eth0
  in_ns client ip link set eth0 up
  in_ns router ip link set eth0 up
  in_ns router ip link set eth1 up
  in_ns web ip link set eth0 up

  # client and web send everything that is not local to the router
  in_ns client ip route add default via 10.0.1.1
  in_ns web ip route add default via 10.0.2.1
  # the router forwards packets between its two interfaces
  in_ns router sysctl -qw net.ipv4.ip_forward=1

  mkdir -p "$WEBROOT"
  echo "<h1>Hello from the web server at 10.0.2.10</h1>" > "$WEBROOT/index.html"
  ip netns exec pl-web python3 -m http.server 80 --bind 10.0.2.10 --directory "$WEBROOT" >/dev/null 2>&1 &
  echo $! > "$PIDFILE"
  # wait until the web server accepts connections (up to 10 seconds)
  for _ in $(seq 1 100); do
    in_ns web bash -c 'exec 3<>/dev/tcp/10.0.2.10/80' 2>/dev/null && break
    sleep 0.1
  done
  echo "Lab is up:  client 10.0.1.10 --- 10.0.1.1 router 10.0.2.1 --- 10.0.2.10 web"
  echo "Open a shell in each with:  sudo $0 sh client | router | web"
}

status() {
  for n in "${NS[@]}"; do
    echo "== $n"
    in_ns "$n" ip -br addr show | grep -v '^lo'
    in_ns "$n" ip -br link show | grep -v '^lo' | awk '{print "   MAC " $1 ": " $3}'
  done
}

need_root
case "${1:-}" in
  up) up ;;
  down) down; echo "Lab removed." ;;
  status) status ;;
  sh)
    n=${2:?usage: packetlab.sh sh client|router|web}
    exec ip netns exec "pl-$n" env PS1="[$n] \\$ " bash --norc
    ;;
  *) sed -n '2,13p' "$0"; exit 1 ;;
esac

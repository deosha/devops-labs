# Episode 1.2: IP addresses and CIDR

Follow the video on your own machine, then plan the addresses for a three-tier AWS network and check your plan with a script. Each section below matches a "Try it" card in the video.

You need:

- The three-machine lab from [Episode 1.1](../1.1-packet-path/) (`packetlab.sh`), on the same Linux machine as last time. If you haven't set one up, follow step 1 of that lab first.
- Python 3, which Ubuntu already has. The commands use Python's built-in `ipaddress` module, so there is nothing to install.

Commands marked **host** run in a normal shell. Commands marked **client** run inside the client machine: open a shell there with `sudo ./packetlab.sh sh client` from the 1.1 folder.

## 1. Start the lab (host)

```bash
cd ../1.1-packet-path
sudo ./packetlab.sh up
```

## 2. An address is one number (host)

```bash
python3 -c "import ipaddress as i; a=i.ip_address('10.0.1.10'); print(int(a), format(int(a),'032b'))"
```

```
167772426 00001010000000000000000100001010
```

## 3. The number after the slash (host)

```bash
python3 -c "import ipaddress as i; n=i.ip_network('10.0.1.10/24', strict=False); print(n, n.netmask, n.num_addresses)"
```

```
10.0.1.0/24 255.255.255.0 256
```

## 4. Same network or not? (client)

```bash
ip route
ip route get 10.0.2.10
```

`10.0.2.10 via 10.0.1.1` means the client sends to the router: 10.0.2.10 is on a different network.

## 5. Break it with /16 (client)

Give the client a /16 instead of a /24:

```bash
ip addr del 10.0.1.10/24 dev eth0
ip addr add 10.0.1.10/16 dev eth0
ip route add default via 10.0.1.1
ip route get 10.0.2.10
curl -m 5 http://10.0.2.10/
ip neigh
```

What you should see:

- `ip route get` no longer says `via 10.0.1.1`: the client now thinks 10.0.2.10 is on its own network.
- `curl: (7) Failed to connect`
- `10.0.2.10 dev eth0 INCOMPLETE`, or `FAILED` once the client gives up: it asked "who has 10.0.2.10?" and nobody answered. Episode 1.3 explains that question (ARP).

Put the /24 back and the page loads again:

```bash
ip addr del 10.0.1.10/16 dev eth0
ip addr add 10.0.1.10/24 dev eth0
ip route add default via 10.0.1.1
curl http://10.0.2.10/
```

## 6. Cutting blocks (host)

```bash
python3 -c "import ipaddress as i; print(list(i.ip_network('10.0.0.0/16').subnets(prefixlen_diff=1))); i.ip_network('10.0.1.0/23')"
```

You get the two /17 halves, then `ValueError: 10.0.1.0/23 has host bits set`. A /23 must start on an even third byte, so 10.0.1.0 can't start one.

## 7. Longest prefix wins (client)

```bash
ip route get 10.0.1.20
ip route get 8.8.8.8
```

10.0.1.20 matches both routes, and the /24 wins, so it goes straight out `eth0`. 8.8.8.8 matches only the default route, so it goes `via 10.0.1.1`.

## 8. Sixteen /20 blocks (host)

```bash
python3 -c "import ipaddress as i; [print(n) for n in i.ip_network('10.0.0.0/16').subnets(new_prefix=20)]"
```

## 9. Clean up (host)

```bash
sudo ./packetlab.sh down
```

On AWS, stop your instance if you're done for the day.

## Lab task: plan a three-tier network

Design the network for the course project and check it with [`subnetcheck.py`](subnetcheck.py).

**The brief**

- The company already uses `10.0.0.0/16` (an existing VPC) and `192.168.0.0/16` (the office). Your new VPC must not overlap either. So you can't copy the plan from the video.
- Three tiers in two availability zones: `public-a`, `public-b`, `app-a`, `app-b`, `data-a`, `data-b`.
- Usable addresses per subnet, after the five AWS reserves in every subnet: public at least 200, app at least 2,000, data at least 100.
- Leave at least half of the VPC free for later.

**Steps**

1. Choose a VPC block and write it on the first line of `plan.txt` as `vpc <cidr>`.
2. For each tier, find the smallest prefix whose address count, minus 5, meets the need.
3. Place the six subnets so each starts on a multiple of its own size. Add one line per subnet: `name cidr`.
4. Run the checker and fix anything marked FAIL:

```bash
python3 subnetcheck.py plan.txt
```

5. Stretch: write the three rules from the video in your own words, and say which checks in the script test each one.

Plans differ, so the checker tests rules, not one fixed answer. A sample plan that passes is in [`plan-example.txt`](plan-example.txt). Try your own first.

#!/usr/bin/env python3
"""Check a subnet plan for Lab 1.2 (IP addresses and CIDR).

Plan file: one entry per line, "name cidr". Blank lines and # comments are ignored.
    vpc       10.1.0.0/16
    public-a  10.1.0.0/24
    ...
Exit code 0 when every check passes, 1 otherwise.
"""
import ipaddress
import sys

# Networks the new VPC must not overlap (the lab's scenario).
TAKEN = {
    "existing VPC": ipaddress.ip_network("10.0.0.0/16"),
    "office network": ipaddress.ip_network("192.168.0.0/16"),
}
# Minimum usable hosts per subnet. AWS reserves 5 addresses in every subnet.
NEED = {"public": 200, "app": 2000, "data": 100}
ZONES = ("a", "b")
AWS_RESERVED = 5


def load(path):
    entries = {}
    with open(path) as fh:
        for n, raw in enumerate(fh, 1):
            line = raw.split("#", 1)[0].strip()
            if not line:
                continue
            parts = line.split()
            if len(parts) != 2:
                sys.exit(f"line {n}: expected 'name cidr', got: {raw.strip()}")
            name, cidr = parts
            try:
                entries[name] = ipaddress.ip_network(cidr)
            except ValueError as err:
                sys.exit(f"line {n}: {err}")
    return entries


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: subnetcheck.py PLAN_FILE")
    plan = load(sys.argv[1])
    results = []

    def check(ok, msg):
        results.append(ok)
        print(("PASS  " if ok else "FAIL  ") + msg)

    vpc = plan.pop("vpc", None)
    if vpc is None:
        sys.exit("plan has no 'vpc' line")
    check(16 <= vpc.prefixlen <= 28 and vpc.is_private,
          f"VPC {vpc} is a private block between /16 and /28")
    for label, net in TAKEN.items():
        check(not vpc.overlaps(net), f"VPC does not overlap the {label} ({net})")

    for tier, need in NEED.items():
        for zone in ZONES:
            name = f"{tier}-{zone}"
            net = plan.get(name)
            if net is None:
                check(False, f"{name} is in the plan")
                continue
            check(net.subnet_of(vpc), f"{name} {net} is inside the VPC")
            usable = net.num_addresses - AWS_RESERVED
            check(usable >= need, f"{name} has {usable} usable addresses (needs {need})")

    nets = sorted(plan.items(), key=lambda kv: kv[1])
    clashes = [(a, b) for i, (a, na) in enumerate(nets) for b, nb in nets[i + 1:] if na.overlaps(nb)]
    check(not clashes, "no two subnets overlap" + "".join(f"; {a} overlaps {b}" for a, b in clashes))

    used = sum(n.num_addresses for _, n in nets if n.subnet_of(vpc))
    free = vpc.num_addresses - used
    check(free * 2 >= vpc.num_addresses,
          f"{free} of {vpc.num_addresses} VPC addresses left free (needs at least half)")

    print(f"\n{sum(results)}/{len(results)} checks passed")
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main())

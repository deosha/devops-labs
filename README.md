# DevOps Labs

[![CI](https://github.com/deosha/devops-labs/actions/workflows/ci.yml/badge.svg)](https://github.com/deosha/devops-labs/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Hands-on labs for the DevOps video series by Deo Shankar. Each lab rebuilds what the video explains, so you can watch a concept and then see it for yourself on a real machine.

## How it works

1. **Set up once.** Follow [Episode 0](00-setup-aws/) to create an AWS account with a budget alert and a small Ubuntu EC2 instance. This is your lab machine.
2. **Watch an episode.** When a "Try it" card appears in the video, pause.
3. **Run the lab.** Open the episode's folder below and follow its README on your lab machine.
4. **Clean up.** Every lab ends with cleanup steps. Terminate cloud resources you no longer need.

The labs follow the **100 Days of Project-Based DevOps, 2026 edition**: Day 0 is setup, Days 1–84 are the nine courses below (one episode a day), and Days 85–100 are GenAI for DevOps. Coming from the 2023 Medium post? [This map](100-days-2023-map.md) shows where each 2023 day lives now.

The course uses AWS, but the ideas are the same on any cloud. Where a lab uses an AWS-only service, its README names the Azure and Google Cloud equivalents. Many early labs run on any Linux machine.

## Labs

| Course | Episode | Lab | Status |
| --- | --- | --- | --- |
| 0. Setup | 0 | [Set up your cloud lab](00-setup-aws/) | Available |
| 1. Networking Foundations | 1.1 | [How a packet crosses the internet](01-networking/1.1-packet-path/) | Available |
| 1. Networking Foundations | 1.2 | [IP addresses and CIDR](01-networking/1.2-cidr/) | Available |
| 2. Linux for Operators | | | Planned |
| 3. AWS and Infrastructure as Code | | | Planned |
| 4. Containers and Kubernetes | | | Planned |
| 5. CI/CD and GitOps | | | Planned |
| 6. Data Services in Production | | | Planned |
| 7. Observability | | | Planned |
| 8. Security and DevSecOps | | | Planned |
| 9. Reliability, Chaos and Cost | | | Planned |
| 10. GenAI for DevOps (Days 85–100) | | | Planned |

## Safety

- **Never commit keys or credentials.** This repo's `.gitignore` blocks common key files, but check before every push.
- **Watch your bill.** Set the budget alert in Episode 0 before launching anything.
- **Run labs on a lab machine**, not on a server you care about. Some labs change network settings.

## Continuous integration

Every lab is tested on a fresh Ubuntu 24.04 machine by [GitHub Actions](.github/workflows/ci.yml) on every push, on every pull request and once a week. A green badge at the top means every lab works today.

| Check | What it does |
| --- | --- |
| ShellCheck | Lints every shell script |
| Internal links | Fails if a README links to a file or folder that does not exist ([`tests/check-links.py`](tests/check-links.py)) |
| Lab 1.1 | Builds the three-machine network and checks every claim from the video: the page loads, the destination MAC is the router's, the routing tables, TTL 64 on one side of the router and 63 on the other, MAC addresses change while IP addresses stay the same, a TTL-1 ping gets "Time to live exceeded", the reply comes back with HTTP 200, and cleanup removes everything ([`tests/lab-1.1.sh`](tests/lab-1.1.sh)) |
| Lab 1.2 | Checks every command and output from the video: the 32-bit number, the /24 mask, /17 halves and the rejected 10.0.1.0/23, sixteen /20 blocks, longest prefix match, the /16 break (no route via the router, no ARP answer, the request fails) and the fix, and that the plan checker passes the sample plan and catches overlaps, undersized subnets, misaligned blocks and a copy of the video's plan ([`tests/lab-1.2.sh`](tests/lab-1.2.sh)) |

Run the same checks yourself on any Linux machine:

```bash
sudo tests/lab-1.1.sh
sudo tests/lab-1.2.sh
python3 tests/check-links.py
```

## Licence

[MIT](LICENSE). Use, adapt and share the labs freely; keep the copyright notice.

## Feedback

Found a step that doesn't work, or output that differs from the video? Open an issue with the episode number, what you ran, and what you saw.

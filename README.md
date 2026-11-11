# DevOps Labs

Hands-on labs for the DevOps video series by Deo Shankar. Each lab rebuilds what the video explains, so you can watch a concept and then see it for yourself on a real machine.

## How it works

1. **Set up once.** Follow [Episode 0](00-setup-aws/) to create an AWS account with a budget alert and a small Ubuntu EC2 instance. This is your lab machine.
2. **Watch an episode.** When a "Try it" card appears in the video, pause.
3. **Run the lab.** Open the episode's folder below and follow its README on your lab machine.
4. **Clean up.** Every lab ends with cleanup steps. Terminate cloud resources you no longer need.

The course uses AWS, but the ideas are the same on any cloud. Where a lab uses an AWS-only service, its README names the Azure and Google Cloud equivalents. Many early labs run on any Linux machine.

## Labs

| Course | Episode | Lab | Status |
| --- | --- | --- | --- |
| 0. Setup | 0 | [Set up your cloud lab](00-setup-aws/) | Available |
| 1. Networking Foundations | 1.1 | [How a packet crosses the internet](01-networking/1.1-packet-path/) | Available |
| 1. Networking Foundations | 1.2 | IP addresses and subnets | Coming soon |
| 2. Linux for Operators | | | Planned |
| 3. AWS and Infrastructure as Code | | | Planned |
| 4. Containers and Kubernetes | | | Planned |
| 5. CI/CD and GitOps | | | Planned |
| 6. Data Services in Production | | | Planned |
| 7. Observability | | | Planned |
| 8. Security and DevSecOps | | | Planned |
| 9. Reliability, Chaos and Cost | | | Planned |

## Safety

- **Never commit keys or credentials.** This repo's `.gitignore` blocks common key files, but check before every push.
- **Watch your bill.** Set the budget alert in Episode 0 before launching anything.
- **Run labs on a lab machine**, not on a server you care about. Some labs change network settings.

## Feedback

Found a step that doesn't work, or output that differs from the video? Open an issue with the episode number, what you ran, and what you saw.

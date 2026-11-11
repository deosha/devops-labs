# Episode 1.1: How a packet crosses the internet

Build the network from the video on one Linux machine and watch a real request cross a router. Each section below matches a "Try it" card in the video.

```
client 10.0.1.10 --- 10.0.1.1 router 10.0.2.1 --- 10.0.2.10 web
```

The three "machines" are Linux network namespaces joined by virtual cables. Nothing leaves your computer and nothing is installed permanently.

## 1. Get a Linux machine

This course uses AWS, but nothing in this lab is AWS-specific. An Azure or Google Cloud VM, or any Linux machine, works the same way.

### On AWS (the course default)

If you set up your lab machine in [Episode 0](../../00-setup-aws/), use it and skip to step 2. Otherwise:

1. Sign in with your admin user (not root) and open the EC2 console in your chosen region.
2. Choose **Launch instance**. Name it `packetlab`, pick **Ubuntu Server 24.04 LTS**, and choose the smallest instance type marked free-tier eligible.
3. Under **Key pair**, create a new key pair and download the `.pem` file.
4. Under **Network settings**, allow SSH from **My IP** only. Add no other inbound rules.
5. Launch, copy the instance's public IPv4 address, and connect from your laptop:

```bash
chmod 400 packetlab.pem
scp -i packetlab.pem packetlab.sh ubuntu@<public-ip>:
ssh -i packetlab.pem ubuntu@<public-ip>
```

You will need four SSH sessions in total: one to start the lab and one for each machine in it. Run the same `ssh` command in three more terminal tabs.

When you finish, **terminate** the instance. Stop it instead only if you will continue soon: a stopped instance still pays for its disk.

### Anywhere else

| You have | Do this |
| --- | --- |
| Linux laptop | Use it directly. |
| Windows | Install WSL2 with Ubuntu (`wsl --install`), then open Ubuntu. |
| macOS | Start a small Linux VM, for example with Multipass: `multipass launch --name packetlab`, then `multipass shell packetlab`. |
| Azure or Google Cloud | Create a small Ubuntu 24.04 VM with SSH open to your IP only, then follow the AWS steps from `scp` onward. |

Tested on Ubuntu 24.04. The EC2, macOS and WSL2 routes use the same script; if a step fails there, please open an issue.

## 2. Install the tools and start the lab

```bash
sudo apt update
sudo apt install -y iproute2 tcpdump curl python3 iputils-ping
chmod +x packetlab.sh
sudo ./packetlab.sh up
```

Open three terminals (three SSH sessions on a cloud VM) and enter one machine in each:

```bash
sudo ./packetlab.sh sh client
sudo ./packetlab.sh sh router
sudo ./packetlab.sh sh web
```

The prompt shows which machine you are in. Stop any capture with Ctrl-C.

## 3. Follow the video

### Part B: send the request

In **client**:

```bash
curl http://10.0.2.10/index.html
```

You should see `Hello from the web server at 10.0.2.10`.

### Part C: see every layer of one frame

In **router**, listen on the cable that goes to the client:

```bash
tcpdump -i eth0 -e -nn -A tcp port 80
```

In **client**, send the request again with the `curl` command above. In the router output, find:

- two MAC addresses at the start of each line (link layer)
- `10.0.1.10.<port> > 10.0.2.10.80` (network layer addresses, then transport layer ports)
- `GET /index.html HTTP/1.1` in plain text (application layer)

### Part C: whose MAC address is the destination?

In **client**:

```bash
ip neigh
```

In **router**:

```bash
ip -br link
```

The destination MAC of the frames you captured is the router's `eth0`, not the web server's.

### Part D: the routing table

Run `ip route` in **client** and in **router**. The client knows one thing: send everything to 10.0.1.1. The router knows both networks.

### Part D: compare both sides of the router

In **router**, capture the first packet of a connection on the client side:

```bash
tcpdump -i eth0 -e -nn -v -c 1 'tcp[tcpflags] == tcp-syn'
```

Run `curl` in **client**. Then repeat with `-i eth1`, the web server side, and run `curl` again. Compare the two lines:

| | Client side (eth0) | Server side (eth1) |
| --- | --- | --- |
| MAC addresses | client to router | router to web: both changed |
| IP addresses | 10.0.1.10 to 10.0.2.10 | the same |
| ttl | 64 | 63 |

`cksum ... incorrect` in the output is normal here. The kernel leaves the checksum to the network card, and a virtual cable has none.

### Part D: time to live reaching zero

In **client**, send a packet that is only allowed one hop:

```bash
ping -c 1 -t 1 10.0.2.10
```

The reply `Time to live exceeded` comes from 10.0.1.1: the router dropped the packet and said so.

### Part E: the reply

In **web**:

```bash
tcpdump -i eth0 -nn -A tcp port 80
```

Run `curl` in **client**. Look for `HTTP/1.0 200 OK` travelling from `10.0.2.10.80` back to the client's port: source and destination swapped.

## 4. Clean up

Type `exit` in each of the three terminals, then:

```bash
sudo ./packetlab.sh down
```

On AWS, terminate the EC2 instance as well, unless you are going straight on to the next episode.

# Episode 0: Set up your cloud lab

By the end you will have a safe AWS account and a small Ubuntu machine you can reach over SSH. Every later lab uses it.

Already have a Linux machine you can use? You can skip to the episode labs; most early labs work anywhere. Come back here before the cloud courses.

## 1. Create an AWS account and choose a plan

Sign up at [aws.amazon.com](https://aws.amazon.com/). You will be asked to choose a plan:

| Plan | What it means |
| --- | --- |
| Free plan | New accounts get credits and your card is not charged. AWS closes the account after 6 months or when the credits run out, whichever comes first, unless you upgrade. |
| Paid plan | Normal pay-as-you-go billing. |

**Suggestion:** use the Free plan for Courses 1 to 3, then upgrade to the Paid plan, with the budget alert from step 4 in place, before Course 4 (Kubernetes). The full series takes longer than 6 months.

Check the current terms on the sign-up page; AWS changes them from time to time.

## 2. Protect the root user

The root user (the email you signed up with) can do anything, including close the account.

1. Sign in as root, open your account menu (top right) and choose **Security credentials**.
2. Under **Multi-factor authentication (MFA)**, assign a device: an authenticator app on your phone is fine.
3. From now on, use root only for billing and account settings.

## 3. Create your day-to-day admin user

1. Open **IAM** and create a user called `admin` with access to the AWS Management Console.
2. Attach the **AdministratorAccess** permission.
3. Sign in as `admin`, then turn on MFA for this user too.
4. Use `admin` for every lab.

## 4. Set a budget alert

1. Open **Billing and Cost Management**, then **Budgets**, then **Create budget**.
2. Choose a template: **Zero spend budget** (alerts you as soon as anything costs money) or **Monthly cost budget** with a small amount such as $5.
3. Enter your email address and create it.

This is the cheapest protection against a forgotten resource.

## 5. Pick one region and stay in it

Choose the region closest to you from the menu at the top right, for example **Asia Pacific (Mumbai)** in India. Do every lab in that region: resources left in other regions are easy to forget.

## 6. Launch your lab machine

1. Open **EC2** and choose **Launch instance**.
2. **Name:** `devops-lab`.
3. **Image:** Ubuntu Server 24.04 LTS.
4. **Instance type:** the smallest type marked free-tier eligible.
5. **Key pair:** create a new one, type RSA or ED25519, format `.pem`. Your browser downloads the file. Keep it safe and never share or commit it.
6. **Network settings:** allow SSH traffic from **My IP** only. Do not open any other ports.
7. Leave storage at the default and choose **Launch instance**.

## 7. Connect over SSH

Copy the instance's **Public IPv4 address** from the EC2 console, then on your laptop:

```bash
chmod 400 ~/Downloads/devops-lab.pem
ssh -i ~/Downloads/devops-lab.pem ubuntu@<public-ip>
```

On Windows, run the same commands in WSL or PowerShell.

If SSH times out, your home IP address has probably changed: edit the instance's security group and set the SSH rule to **My IP** again.

## 8. First commands

```bash
uname -a          # which kernel you are running
ip -br addr       # your network interfaces and addresses
sudo apt update   # refresh the package lists
```

If all three work, your lab machine is ready.

## 9. Stop, start and clean up

| Action | What happens | Cost |
| --- | --- | --- |
| **Stop** | The machine shuts down; the disk is kept | You still pay for the disk |
| **Start** | It boots again, usually with a new public IP | Normal running cost |
| **Terminate** | The machine and its disk are deleted | Nothing more |

**Cleanup checklist after each session:**

- Stop the instance if you will continue within a few days; terminate it otherwise.
- Look at the EC2 dashboard once a week for anything you forgot.
- Check that the budget alert email arrives if something does cost money.

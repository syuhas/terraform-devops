# DevOps Infrastructure Challenge – Secure VPC with HTTPS Load Balancer and Private Web Server

## Overview

This project provisions secure infrastructure on AWS using Terraform to simulate a real-world cloud deployment scenario. It includes a web server running in a private subnet, publicly accessible via an Application Load Balancer with HTTPS. Additional configuration was added to support installation of necessary packages and optional SSH access for debugging.

The infrastructure supports optional access to the private EC2 instance through a bastion host if a valid key pair is provided. A self-signed SSL certificate is used to demonstrate HTTPS termination at the load balancer.

---

## Tools Used

- **Terraform** v1.11.3
- **Amazon Linux 2023** AMI
- **NGINX** (installed via `dnf`)
- **OpenSSL** (used to generate the self-signed certificate)
- **GitHub** (source-controlled infrastructure)

---

## Requirements & Installation

This project can be run in either **WSL/Linux** or **Windows**.

| Tool        | WSL/Linux Install                                | Windows Install                                         |
|-------------|--------------------------------------------------|----------------------------------------------------------|
| Terraform   | `wget -O - https://apt.releases.hashicorp.com/gpg \| sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg` | [Install Terraform](https://developer.hashicorp.com/terraform/downloads) |
|    | `echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \| sudo tee /etc/apt/sources.list.d/hashicorp.list` | - |
|    | `sudo apt update && sudo apt install terraform` | - |
| AWS CLI     | `curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"` | [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
|    | `curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"` | - |
|    | `unzip awscliv2.zip` | - |
|    | `sudo ./aws/install` | - |
|    | (update)`sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update` | - |
| OpenSSL     | `sudo apt install openssl` | [Win64 OpenSSL](https://slproweb.com/products/Win32OpenSSL.html) → Add `bin/` to PATH |
| Git         | `sudo apt install git` | [Git for Windows](https://git-scm.com/download/win)      |

---

## Assumptions Made

1. **NAT Gateway Required for Private Subnet**
   - *Why:* The instance is in a private subnet, and does not have a public IP.
   - A NAT Gateway is necessary to provide internet access so that `dnf install nginx` can succeed.

2. **(Optional) Bastion Host for SSH Access**
   - *Why:* SSH port access was mentioned but the instance is on a private subnet meaning SSH is not possible without further configuration.
   - A bastion is a reasonable assumption here as I wanted to SSH into the instance to debug any issues.

3. **HTTPS Termination at the ALB**
   - *Why:* To meet the requirement of a secure, browser-accessible web server.
   - A self-signed certificate is sufficient for verifying SSL setup.
   - The exercise did not require a trusted CA cert, only that SSL be in place. The browser may throw exceptions but this is expected behavior.

4. **HTTP Redirect to HTTPS**
   - *Why:* Added as best practice to ensure all traffic is encrypted.

5. **(Optional) Key Pair Must Be Provided by the User**
   - *Why:* To maintain security and avoid storing private keys in the repo.
   - Users familiar with SSH can provide a valid EC2 key pair and jump host the bastion for access if opted in.

6. **Certificate Created Locally Using Script**
   - *Why:* AWS ACM does not support uploading self-signed certs via Terraform directly.
   - It's acceptable to generate the cert locally via bash (or ps1).

---

## Installation & Usage

### 1. Generate a Self-Signed Certificate

Before deploying, run this to create your cert and key:
```bash
./generate_certs.sh
```

This will create:
- `certs/localhost.localhost.com.crt`
- `certs/localhost.localhost.com.key`

These files are used to simulate HTTPS termination on the ALB.

---

### 2. Initialize Terraform

```bash
terraform init
```

---

### 3. Deploy the Stack

#### Option A: No SSH / Bastion (Default)
```bash
terraform apply -auto-approve
```

#### Option B: Enable Bastion Access
Edit or create `options.tfvars`:
```hcl
enable_bastion = true
key_pair_name  = "your-aws-key-name"
```

Then apply:
```bash
terraform apply -var-file="options.tfvars"
```

---

## SSH Access (If Enabled)

If `enable_bastion = true`, you can SSH into your private EC2 instance via the bastion host:

```bash
ssh -i your-key.pem ec2-user@<bastion-public-ip>
# Then from inside bastion:
ssh -i your-key.pem ec2-user@<private-ip>
```

Or directly from your local machine using jump host syntax:
```bash
ssh -i your-key.pem -J ec2-user@<bastion-ip> ec2-user@<private-ip>
```

---

## Access the Web Server

### Via Browser:
Navigate to:
```
https://<alb-dns-name>
```

- You will see a self-signed certificate warning — this is expected.
- Continue through the warning to view the styled NGINX welcome page.

### Via `curl`:
```bash
curl -vk https://<alb-dns-name>
```

You should see:
- HTTP/1.1 200 OK
- Content from your custom NGINX index page

---

## Cleanup

To destroy all resources:
```bash
terraform destroy -auto-approve
```

Make sure to delete your `.pem` key file and clean up any generated certs after testing.

---

## Final Notes

- This project follows infrastructure-as-code best practices using Terraform.
- All modules are configurable, optional features like bastion access are toggleable.
- SSL setup uses a realistic ALB-terminated pattern for modern web architectures.

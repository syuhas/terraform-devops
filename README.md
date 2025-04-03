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

## Assumptions Made

1. **NAT Gateway Required for Private Subnet**
   - *Why:* The EC2 instance resides in a private subnet with no public IP.
   - *Assumption:* A NAT Gateway is necessary to provide internet access so that `dnf install nginx` can succeed.
   - *Based on:* The instructions imply NGINX must be installed but no public IP should be assigned.

2. **Optional Bastion Host for SSH Access**
   - *Why:* To verify that NGINX and the EC2 instance are functioning correctly.
   - *Assumption:* A bastion is a reasonable DevOps tool for SSH access to private instances and helps with debugging.
   - *Based on:* The private instance is not publicly accessible, but testing/debugging may be required.

3. **HTTPS Termination at the ALB**
   - *Why:* To meet the requirement of a secure, browser-accessible web server.
   - *Assumption:* A self-signed certificate is sufficient for verifying SSL setup.
   - *Based on:* The exercise did not require a trusted CA-signed cert, only that SSL be in place.

4. **HTTP Redirect to HTTPS**
   - *Why:* This is a standard security best practice to ensure all traffic is encrypted.
   - *Assumption:* Allowed to go beyond base requirements to show awareness of best practices.

5. **Key Pair Must Be Provided by the User**
   - *Why:* To maintain security and avoid storing private keys in the repo.
   - *Assumption:* Users familiar with SSH can provide a valid EC2 key for bastion access if needed.
   - *Based on:* The instructions mention no public IP, implying secure access must be indirect.

6. **Certificate Created Locally Using Script**
   - *Why:* AWS ACM does not support uploading self-signed certs via Terraform directly.
   - *Assumption:* It's acceptable to generate the cert locally via bash.
   - *Based on:* Instructions align with methods shown in other public examples like [syuhas/terraform-devops](https://github.com/syuhas/terraform-devops).

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

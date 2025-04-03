# DevOps Infrastructure Exercise – Secure VPC with HTTPS Load Balancer and Private Web Server


## Overview

This project provisions secure infrastructure on AWS using Terraform to simulate a real-world cloud deployment scenario. It includes a web server running in a private subnet, publicly accessible via an Application Load Balancer with HTTPS. Additional configuration was added to support installation of necessary packages and optional SSH access for debugging.

WSL/Linux was used to perform all of the scripting and Terraform steps. I also included some instructions for Windows in case this will be run in from a Windows environment.

The infrastructure supports optional access to the private EC2 instance through a bastion host if a valid key pair is provided. A self-signed SSL certificate is used to demonstrate HTTPS termination at the load balancer.

In additional to deploying this locally, I deployed this infrastructure with Jenkins as well. A brief overview of how I configured this is listed at the end of this exercise overview.

<br><br>
---
## Table of Contents

- [Tools Used](#tools-used)
- [Requirements & Installation](#requirements--installation)
  - [AWS Permissions](#aws-permissions)
  - [Bastion Host Configuration (optional)](#bastion-host-configuration-optional)
- [Terraform Steps](#terraform-steps)
  - [1. Clone the Repo](#1-clone-the-repo)
  - [2. Generate Self-Signed Certificate](#2-generate-self-signed-certificate)
  - [3. Initialize Terraform](#3-initialize-terraform)
  - [4. Deploy the Stack](#4-deploy-the-stack)
  - [5. SSH Access (If Enabled)](#5-ssh-access-if-enabled)
- [Verification](#verification)
- [Cleanup](#cleanup)
- [Bonus Section: Deploying with Jenkins](#bonus-section-deploying-with-jenkins)
---
<br><br>

## Assumptions Made

1. **NAT Gateway Required for Private Subnet**
   - *Why:* The instance is in a private subnet, and does not have a public IP.
   - A NAT Gateway is necessary to provide internet access so that `dnf install nginx` can succeed.

2. **(Optional) Bastion Host for SSH Access**
   - *Why:* SSH port access was mentioned but the instance is on a private subnet meaning SSH is not possible without further configuration.
   - A bastion is a reasonable assumption here as I wanted to SSH into the instance to debug any issues.

3. **HTTP Redirect to HTTPS**
   - *Why:* Added as best practice to ensure all traffic is encrypted.

4. **(Optional) Key Pair Must Be Provided by the User**
   - *Why:* To maintain security and avoid storing private keys in the repo.
   - A valid EC2 key pair can be provided to jump host through the bastion into the instance for access (if opted in).

5. **Certificate Created Locally Using Script**
   - *Why:* AWS ACM does not support uploading self-signed certs via Terraform directly.
   - The exercise did not require a trusted CA cert, only that SSL be in place. The browser may throw exceptions but this is expected behavior.

6. **AWS Permissions are Setup**
   - *Why:* The exercise does not explicitly mention configuring an IAM user or specifying permissions required to run the infrastructure.
   - It is assumed that the user running this has appropriate AWS credentials configured and the necessary permissions.
   - However, to ensure completeness, I have included both broad and scoped IAM policies that can be used to create a user or role with the minimum required permissions to get started.

---
<br><br><br><br>


## Tools Used

- **Terraform** v1.11.3
- **Amazon Linux 2023** AMI (ami-00a929b66ed6e0de6) (t2.micro)
- **NGINX** (installed via `dnf`)
- **OpenSSL** (used to generate the self-signed certificate)
- **GitHub** (source-controlled infrastructure)


---
[Back To Top](#table-of-contents)
<br><br><br><br>

## Requirements & Installation

This project can be run in either **WSL/Linux** or **Windows**.

| Tool        | WSL/Linux Install                                | Windows Install                                         |
|-------------|--------------------------------------------------|----------------------------------------------------------|
| Terraform   | `wget -O - https://apt.releases.hashicorp.com/gpg \| sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg` | [Install Terraform](https://developer.hashicorp.com/terraform/downloads) |
|    | `echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \| sudo tee /etc/apt/sources.list.d/hashicorp.list` | - |
|    | `sudo apt update && sudo apt install terraform` | - |
| AWS CLI     | `curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"` | [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
|    | `unzip awscliv2.zip` | - |
|    | `sudo ./aws/install` | - |
|    | (update)`sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update` | - |
| OpenSSL     | `sudo apt install openssl` | [Win64 OpenSSL](https://slproweb.com/products/Win32OpenSSL.html) → Add `bin/` to PATH |
| Git         | `sudo apt install git` | [Git for Windows](https://git-scm.com/download/win)      |

---
[Back To Top](#table-of-contents)
<br><br><br><br>



### AWS Permissions

An AWS user (or role) will need to be utilized via the CLI in order to use Terraform locally. I have included both a scoped policy and a broader policy (iam_policies/scoped_policy.json, iam_policies/broad_policy.json). Create an inline or managed policy with either of policy jsons and attach to the resource. (**NOTE** In production, these would be conditionally scoped further to align with least priviledge, but for testing the policies are both scoped to all resources.)

#### Option A: Configure User Directly
To configure user locally:

```bash
aws configure
```

Enter AWS Access Key ID, AWS Secret Access Key, Default Region Name (us-east-1) and Default Output Format (leave blank or json).

#### Option B: Assume IAM Role Locally

Add to ~/.aws/config

```bash
[profile terraform-role]
role_arn = arn:aws:iam::123456789012:role/MyTerraformRole
source_profile = base-user
region = us-east-1
```

```bash
export AWS_PROFILE=terraform-role
```

Then continue with Terraform steps.

[Back To Top](#table-of-contents)

---
<br><br><br><br>



 
### Bastion Host Configuration (optional)

In order to use the optional Bastion host to SSH into the private instance, a `key pair` is required and `enable_bastion` flag will need to be set in the optional tfvars file.

**In the Console**:

- Navigate to `EC2` > `Key Pairs` > `Create Key Pair`
- Enter a `Key Pair Name`
- Choose `RSA` type encryption
- Choose `pem` format
- Click `Create Key Pair` and save key pair to desired location locally

**In the CLI**: 

Using WSL/Linux (or if jq installed on Windows):

```bash
aws ec2 create-key-pair --key-name "tfkey" --key-type "rsa" --key-format "pem" | jq -r .KeyMaterial > tfkey.pem
```

OR 

Using Windows:

```powershell
$key = aws ec2 create-key-pair --key-name "tfkey" --key-type "rsa" --key-format "pem" | ConvertFrom-Json
$key.KeyMaterial | Out-File -Encoding ascii -FilePath tfkey.pem
```

Edit or create new `options.tfvars` at the project base directory:

```bash
enable_bastion = true
key_pair_name  = "tfkey"
```

---
[Back To Top](#table-of-contents)
<br><br><br><br>






# Terraform Steps

## 1. Clone the Repo
```bash
git clone https://github.com/syuhas/terraform-devops.git
cd terraform-devops
```

## 2. Generate Self-Signed Certificate

Before deploying, run this to create your cert and key:
#### WSL/Linux:
```bash
./generate_certs.sh
```

#### Windows (PowerShell):
```powershell
./generate_certs_windows.ps1
```

This will create:
- `certs/localhost.localhost.com.crt`
- `certs/localhost.localhost.com.key`

These files are used to simulate HTTPS termination on the ALB.

\*\* [PowerShell Script Troubleshooting](#powershell-script-notes)

---

## 3. Initialize Terraform

```bash
terraform init
```

## 4. Deploy the Stack

#### Option A: No SSH / Bastion (Default)

For no Bastion access, plan the deployment and apply as follows without the tfvars file:

```bash
terraform plan -out=plan.tfplan
terraform apply plan.tfplan -auto-approve
```

#### Option B: Enable Bastion Access

If the tfvars file above has been configured, the `enable_bastion` is set to true, and a valid key pair is entered, plan and apply the following:

```bash
terraform plan -out=plan.tfplan -var-file=options.tfvars
terraform apply plan.tfplan
```

**Deployment in Progress**

![Terraform Apply](https://github.com/user-attachments/assets/94f58d7f-fdd7-4d13-bdaf-a5102d1f24c5)

**Required Outputs Displayed in Console**

![Outputs](https://github.com/user-attachments/assets/ae860aae-bc7c-4dfe-b01d-2b10eaaa77c5)


---

## 5. SSH Access (If Enabled)

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

Additionally, you can configure ssh shortcuts for easier access.
Create or edit ~/.ssh/config and add entries:

```bash
Host bastion
  HostName <bastion-public-ip>
  User ec2-user
  IdentityFile ~/path/to/ec2.pem

Host private-ec2
  HostName <private-ip>
  User ec2-user
  IdentityFile ~/path/to/ec2.pem
  ProxyJump bastion
```

Then ssh into the private instance using:

```bash
ssh private-ec2
```

![SSH](https://github.com/user-attachments/assets/2f037d0c-f33d-4ccf-be21-9dc1abbfb710)

---
[Back To Top](#table-of-contents)
<br><br><br><br>





# Verification 

## Access the Web Server

### Via Browser:
Navigate to:
```
https://<alb-dns-name>
```

![Browser](https://github.com/user-attachments/assets/e7e4a50a-31d2-4379-8fa6-e481afc3b87e)

- You will see a self-signed certificate warning — this is expected.
- Continue through the warning to view the styled NGINX welcome page.

### Via `curl`:
```bash
curl -vk https://<alb-dns-name>
```

![Curl](https://github.com/user-attachments/assets/503628bd-dd73-4052-bcf8-6bd0e4a2c069)


You should see:
- HTTP/1.1 200 OK
- Content from your custom NGINX index page


---
[Back To Top](#table-of-contents)
<br><br><br><br>



## View Resources in AWS

All resources should now have been successfully deployed to AWS. Pictures for reference.
![Certs](https://github.com/user-attachments/assets/e6a30010-b9de-4b8b-9396-c3f458044446)

![SG](https://github.com/user-attachments/assets/a9812964-06f7-4782-99af-2773dea50065)

![LB](https://github.com/user-attachments/assets/4840987b-cb7c-4c53-aa66-1c25c4f043b1)

![chrome_eFR9aLFOka](https://github.com/user-attachments/assets/f941eb29-9569-42cc-9739-1b53bfc040bc)

![VPC](https://github.com/user-attachments/assets/1c6faa9b-6f4f-431f-931c-2353390cb96d)

![EC2](https://github.com/user-attachments/assets/7f83fe41-7dc8-468e-b799-b06585523548)




---
[Back To Top](#table-of-contents)
<br><br><br><br>


## Cleanup

To destroy all resources:
```bash
terraform destroy -auto-approve
```

Make sure to delete your `.pem` key file and clean up any generated certs after testing.

---
[Back To Top](#table-of-contents)
<br><br><br><br>

## Final Notes

- This project follows infrastructure-as-code best practices using Terraform.
- All modules are configurable, optional features like bastion access are toggleable.
- SSL setup uses a realistic ALB-terminated pattern for modern web architectures.


---
<br><br><br><br>




#### PowerShell Script Notes:
If the script doesn't run due to execution policy:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

If `openssl` is not recognized:
- Ensure OpenSSL is installed (use [Win64 OpenSSL](https://slproweb.com/products/Win32OpenSSL.html))
- Add the `bin` folder to your system PATH (e.g., `C:\Program Files\OpenSSL-Win64\bin`)

---

[Back To Top](#table-of-contents)
---
<br><br><br><br>

## Bonus Section: Deploying with Jenkins

I decided to also go ahead and try deploying this setup with Jenkins just to test out the functionality and make testing easier. Check out the Jenkinsfile and configuration for the backend states in the `jenkins` branch of this repository.
- [Jenkins Branch](https://github.com/syuhas/terraform-devops/tree/jenkins)

Since I have a dedicated server living on AWS, the server is accessible through guest credentials and my project can be viewed here with read-only permissions:
- [Jenkins Server](https://jenkins.digitalsteve.net/)
- Username: `guest`
- Password: `password`
- Job Name: `devops-exercise`

With this limited login role, the user can view the project job pipeline and logs.

**Additional Jenkins Configuration**

For all of my Jenkins Terraform deployment, I use a state locking combination of S3 and DynamoDB to track states across my projects. I added this to the Terraform block in the jenkins branch to save states across the project.

```bash
terraform {
  backend "s3" {
    bucket         = "terraform-lock-bucket"
    key            = "devops-exercise-jenkins/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
  }
}
```

Then a simple pipeline was created and configured to pull directly from GitHub and run the same steps that are being run locally for this project, but with the ability to build and tear down the infrastructure with one click.

![chrome_3K3S8VS1RT](https://github.com/user-attachments/assets/fbe3dfff-4361-4575-bf75-361a9b847de1)

**Deploy** runs a new stack or updates an existing stack.
**Destroy** tears down the existing stack saved in the state file.

My Jenkins server uses a dynamically provisioned build server with IMDSv2 role attached to perform all of the infrastructure deployment for Terraform. The build server comes pre-built with Terraform as it is spun up viz an initialization script.

**Pipeline Configuration**

![chrome_wpjtRFwnFQ](https://github.com/user-attachments/assets/bbfdd3c0-a3ff-4b4e-b8cc-d39e9c23e9bf)

![chrome_Sw2M9MCO2o](https://github.com/user-attachments/assets/9141b0cc-d847-49e4-b579-8ce2b69e0e37)


Once the pipeline is kicked off, it runs the steps as defined in the Jenkinsfile and tears down the build server when finished.

![chrome_y2J3kML91Y](https://github.com/user-attachments/assets/c5ece0ea-ccb4-438b-8645-6bba3536e7fa)

![chrome_fMlDr5MRpR](https://github.com/user-attachments/assets/83608d8a-f23a-4524-8587-b30a2d3ff16e)

This makes testing a bit quicker and easier to build up and tear down in case I need to make any changes or for any issues I ran into when deploying.

<br><br>

This section is obviously completely optional and I only added this project to Jenkins to make testing and deploying easier and quicker.

---
[Back To Top](#table-of-contents)


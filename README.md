
# DevOps Infrastructure Challenge – Secure VPC with HTTPS Load Balancer and Private Web Server


---

##  Assumptions Made

- ✅ A NAT Gateway is required for `dnf` (NGINX) installation on private EC2
- ✅ A bastion host is required if SSH access or debugging is needed
- ✅ The SSL certificate is self-signed, so browsers will show a warning — this is acceptable for the exercise
- ✅ The certificate terminates at the ALB, not the EC2 instance
- ✅ Users must supply a valid EC2 key pair if they want SSH access
- ✅ No domain is configured (access via ALB DNS)
- ✅ HTTP-to-HTTPS redirect was implemented as a best practice

---

##  Usage

### 1. Clone and initialize:
```bash
terraform init
```

### 2. Option A: No SSH access (default)
```bash
terraform apply -auto-approve
```

### 2. Option B: With Bastion Host + SSH
1. First, create a key pair in AWS EC2 → Key Pairs
2. Then run:
```bash
terraform apply -var-file="options.tfvars"
```

Example `options.tfvars`:
```hcl
enable_bastion = true
key_pair_name  = "your-aws-key-name"
```

---

## 🔑 SSH Access (if bastion enabled)

```bash
ssh -i your-key.pem ec2-user@<bastion-public-ip> -J ec2-user@<private-ip>
```

Or use the ProxyJump method:
```bash
ssh -i your-key.pem -J ec2-user@<bastion-ip> ec2-user@<private-ip>
```

---

##  Access the Site

Once deployed, open your browser and navigate to:

```
https://<load-balancer-dns>
```

You’ll likely see a browser warning (self-signed cert) — **this is expected**. Click through and verify:

✅ NGINX page loads  
✅ Page contains custom HTML and styling  
✅ SSL terminates at the ALB

---

##  Notes

- The project is designed to be minimal, secure, and easily extensible
- All AWS resources are tagged for traceability

- To destroy everything:  
  ```bash
  terraform destroy -auto-approve
  ```

---

##  Cleanup

After testing, remove any unencrypted `.pem` files and destroy your resources to avoid charges.


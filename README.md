# AWS Multi-Tier Architecture (Terraform)

Production-style AWS multi-tier architecture built with Terraform using a **bootstrap + environment** workflow.  
Includes **VPC networking**, **S3 + CloudFront frontend**, **EC2 + ALB API tier**, and **RDS MySQL** database.

---

## ✅ What This Repo Demonstrates

- **Cloud Architecture:** VPC networking, multi-tier layout, CDN-backed frontend, API behind a load balancer, managed database  
- **Security Isolation:** tiered network boundaries, security groups between ALB → EC2 → RDS  
- **Resilience:** ALB health checks, decoupled tiers, CloudFront edge caching  
- **Cost Awareness:** modular design with environment variables (easy to right-size)  
- **Terraform Best Practices:** module-based structure + separate bootstrap phase + dev/prod environments  

---

## 🗂 Repository Structure (Matches This Repo)

```text
.
├─ bootstrap/
│  ├─ artifacts_bucket.tf
│  ├─ main.tf
│  ├─ outputs.tf
│  ├─ providers.tf
│  ├─ variables.tf
│  └─ versions.tf
│
├─ env/
│  ├─ dev/
│  │  ├─ backend.hcl
│  │  ├─ backend.tf
│  │  ├─ main.tf
│  │  ├─ outputs.tf
│  │  ├─ providers.tf
│  │  ├─ terraform.tfvars
│  │  ├─ variables.tf
│  │  └─ versions.tf
│  └─ prod/
│     ├─ backend.hcl
│     ├─ backend.tf
│     ├─ main.tf
│     ├─ outputs.tf
│     ├─ providers.tf
│     ├─ terraform.tfvars
│     ├─ variables.tf
│     └─ versions.tf
│
└─ modules/
   ├─ network/
   ├─ frontend_s3_cf/
   ├─ api_ec2_alb/
   └─ rds_mysql/

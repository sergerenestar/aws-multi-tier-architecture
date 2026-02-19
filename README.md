# AWS Multi-Tier Architecture (Terraform)

Production-style AWS multi-tier architecture built with Terraform using a **bootstrap + environment** workflow.  
Includes **VPC networking**, **S3 + CloudFront frontend**, **EC2 + ALB API tier**, and **RDS MySQL** database.

---

## ✅ What This Repo Demonstrates

- **Cloud Architecture:** VPC networking, multi-tier layout, CDN-backed frontend, API behind a load balancer, managed database
- **Security Isolation:** tiered network boundaries, security groups between ALB → EC2 → RDS
- **Resilience:** ALB health checks, decoupled tiers, CloudFront edge caching
- **Cost Awareness:** modular design with environment variables (easy to right-size)
- **Terraform Best Practices:** module-based structure + separate bootstrap phase

---

## 🗂 Repository Structure (Matches This Repo)

```text
INFRA/
├─ bootstrap/
│  ├─ artifacts_bucket.tf
│  ├─ main.tf
│  ├─ outputs.tf
│  ├─ providers.tf
│  └─ versions.tf
│
└─ env/
   ├─ backend.hcl
   ├─ backend.tf
   ├─ main.tf
   ├─ outputs.tf
   ├─ providers.tf
   ├─ variables.tf
   ├─ terraform.tfvars
   ├─ versions.tf
   └─ modules/
      ├─ network/
      ├─ frontend_s3_cf/
      ├─ api_ec2_alb/
      └─ rds_mysql/

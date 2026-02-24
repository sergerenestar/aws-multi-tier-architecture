# AWS Multi-Tier Architecture (Terraform)

Production-style AWS infrastructure built with Terraform using modular design and environment separation.

This project implements a secure, scalable **3-tier architecture** with distinct **dev** and **prod** environments, following real-world cloud engineering best practices.

## 🏗 Architecture Overview

🌐 **Network Layer**  
VPC · Public & Private Subnets · NAT Gateway · Route Tables · Security Groups

🎨 **Frontend**  
S3 Static Website + CloudFront CDN + Origin Access Control (OAC)

⚙️ **API – Dev**  
Public Application Load Balancer + Single EC2 Instance (cost-efficient)

⚙️ **API – Production**  
Public Application Load Balancer + Auto Scaling Group (multi-AZ)

📊 **Observability**  
CloudWatch Logs (application + system) · Metrics · Alarms · Dashboards

🗄 **Database**  
RDS MySQL in private subnets · No public exposure · Multi-AZ capable

### Architecture Summary

- **Frontend**  
  - S3 static website  
  - CloudFront CDN with Origin Access Control

- **Application Layer**  
  - Public Application Load Balancer  
  - **Dev**: Single EC2 instance (cost-efficient)  
  - **Prod**: Auto Scaling Group across multiple AZs

- **Database**  
  - RDS MySQL running in private subnets  
  - No public access

- **Observability**  
  - CloudWatch Logs (application + system logs)  
  - EC2 / ASG / ALB metrics  
  - Environment-specific dashboards & alarms

## 🔐 Security Design

- Strict tier isolation: **Public → Private → Database**
- **No public IPs** on EC2 or RDS instances
- **SSM Session Manager** for secure access (no open SSH ports)
- Security Groups enforce least privilege:
  - Internet → ALB only
  - ALB → Application (app port)
  - Application → RDS (database port)
- NAT Gateway provides controlled outbound internet access for private resources

## 🚀 High Availability (Production)

- Multi-AZ subnets and resources
- Auto Scaling Group with ELB health checks
- Rolling instance refresh for zero-downtime updates
- CloudFront edge caching and global distribution for frontend

## ⚖️ Dev vs Prod Strategy

| Concern          | Dev                              | Prod                                      |
|------------------|----------------------------------|-------------------------------------------|
| Compute          | Single EC2 instance              | Auto Scaling Group                        |
| Availability     | Basic (single AZ possible)       | Multi-AZ                                  |
| Scaling          | None                             | Automatic (based on CPU, etc.)            |
| CPU Alarm        | Instance-based                   | ASG-based                                 |
| Cost             | Low                              | Higher but resilient & scalable           |

## 🛠 Terraform Best Practices Demonstrated

- Remote state bootstrap (S3 backend)
- Environment-isolated state files (`dev` vs `prod`)
- Reusable, composable modules
- Clear input/output boundaries
- Clean separation of networking, compute, scaling, and observability concerns

## 📂 Repository Structure

bootstrap/           # Remote state bucket + foundational resources
env/
├─ dev/            # Development environment (single EC2)
└─ prod/           # Production environment (ASG + full HA)
modules/             # Reusable infrastructure components
├─ network/
├─ frontend_s3_cf/
├─ api_common_alb/
├─ api_compute_ec2/
├─ api_compute_asg/
└─ api_asg_alb/    # Combined prod stack (ALB + ASG)

## 🎯 What This Demonstrates

- Real-world AWS production architecture patterns
- Clear evolution path: **dev (simple & cheap) → prod (resilient & scalable)**
- Secure-by-default networking design
- Modular and maintainable Terraform code
- Built-in observability (CloudWatch Agent + metrics)
- Cost-aware cloud engineering practices

---

Built for learning, reference, and real-world applicability.
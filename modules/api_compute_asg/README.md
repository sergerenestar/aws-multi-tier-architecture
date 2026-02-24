# api_compute_ec2 Terraform Module

This module provisions a **single-instance** compute layer for a Spring Boot API on AWS — ideal for development, testing, cost-sensitive environments, or simple workloads where auto-scaling is not yet required.

It creates:

- IAM role + instance profile (minimal permissions: S3:GetObject, SSM, CloudWatch)
- Single EC2 instance in a private subnet (Amazon Linux 2023)
- User-data bootstrap script that:
  - Installs Java 17 Corretto + AWS CLI + CloudWatch Agent
  - Downloads the application JAR from S3
  - Configures environment variables (DB creds, CORS, ports, etc.)
  - Starts the app as a systemd service
  - Ships logs & metrics to CloudWatch
- Security group rules allowing traffic only from an ALB

## Component Relationships

```markdown
# 📦 api_compute_ec2 — Component Relationships

This module represents the single-instance compute layer used in the dev environment.

## 🔗 Relationship Between Components

- **IAM Role → Instance Profile → EC2**  
  The IAM role defines permissions (S3 access, SSM, CloudWatch).  
  The Instance Profile attaches that role to the EC2 instance.

- **EC2 → S3 (Artifact Pull)**  
  The EC2 instance pulls the application JAR from the S3 artifact bucket during boot via user-data.

- **User Data → EC2 (Bootstrap Process)**  
  User-data installs Java, downloads the artifact, configures environment variables, and starts the application service.

- **User Data → CloudWatch**  
  Installs and configures the CloudWatch Agent to ship:  
  - Application logs  
  - System logs  
  - Host metrics (CPU, memory, disk)

- **EC2 → CloudWatch**  
  Sends runtime metrics and logs for observability and alarms.

- **SSM → EC2**  
  AWS Systems Manager allows secure remote access (Session Manager) without opening SSH ports.

- **Security Group → EC2**  
  The App Security Group controls inbound traffic (only ALB is allowed to reach the instance).

- **Private Subnet → EC2**  
  The EC2 instance runs in a private subnet for security (no public IP exposure).

  ## Related Modules

This module (`api_compute_ec2`) is part of a family of compute/deployment patterns. Choose the right one based on your environment, traffic expectations, and operational preferences:

| Module                     | Use Case                              | Scaling                        | Best For                     | Key Difference from `api_compute_ec2`                          |
|----------------------------|---------------------------------------|--------------------------------|------------------------------|-----------------------------------------------------------------|
| `api_compute_ec2`          | Development, simple staging, low-traffic | Single instance                | Dev / testing / cost-sensitive | Fixed 1 instance, manual attachment to target group             |
| `api_compute_asg`          | Staging, production, variable traffic | Auto Scaling Group + Launch Template | Prod / scalable workloads    | Dynamic instances, rolling updates, target group ARNs passed in |
| `api_compute_fargate` (future) | Serverless container option       | ECS Fargate                    | Container-first teams        | No EC2 management, container-based                              |
| `api_compute_lambda` (future)  | Event-driven or very low traffic  | AWS Lambda                     | API Gateway + minimal compute | Serverless, pay-per-request                                     |

### Quick Guidance

- **Start with `api_compute_ec2`** in development — it's simple, fast to iterate, and inexpensive.
- **Promote to `api_compute_asg`** for staging and production — same user-data bootstrap logic, but with automatic scaling, better resilience, and zero-downtime updates.
- Consider **Fargate** or **Lambda** later if your team prefers container/serverless workflows or has extremely bursty/event-driven traffic.

This progression keeps the core application deployment (JAR download, CloudWatch Agent, systemd service) consistent across environments while adapting to scale and operational needs.
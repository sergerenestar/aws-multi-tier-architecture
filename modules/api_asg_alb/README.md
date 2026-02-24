# api_asg_alb Terraform Module

This module composes a **complete, production-ready, scalable API deployment** on AWS by combining:

- A public Application Load Balancer (`api_common_alb`)  
- An Auto Scaling Group of EC2 instances (`api_compute_asg`) automatically registered to the ALB's target group

It is the recommended way to deploy your Spring Boot API in staging or production environments where high availability, automatic scaling, and zero-downtime updates are desired.

It creates / composes:

- Public-facing ALB in public subnets with HTTP listener
- Target group with health checks
- Security group rules allowing Internet → ALB → App instances
- Auto Scaling Group in private subnets
- Launch Template with user-data bootstrap (Java 17, JAR download from S3, CloudWatch Agent, systemd service)
- Automatic attachment of ASG instances to the ALB target group

## Component Relationships

```markdown
# 📦 api_asg_alb — Component Relationships

This module represents the full scalable API stack (load balancer + auto-scaling compute).

## 🔗 Relationship Between Components

- **Internet → ALB Security Group**  
  Allows inbound HTTP from anywhere (0.0.0.0/0) to reach the public ALB.

- **ALB Security Group → ALB**  
  The ALB uses this security group to accept public traffic.

- **ALB → HTTP Listener → Target Group**  
  Incoming requests are forwarded via the listener to the target group.

- **Target Group → ASG Instances**  
  The Auto Scaling Group dynamically registers healthy EC2 instances to this target group.

- **ALB Security Group → App Security Group**  
  Adds an ingress rule to the app security group allowing traffic only from the ALB on var.app_port.

- **Public Subnets → ALB**  
  The ALB is placed in public subnets for internet accessibility.

- **Private Subnets → ASG Instances**  
  EC2 instances run in private subnets (no public IP exposure).

- **IAM Role + Instance Profile → Launch Template → ASG Instances**  
  Grants permissions for S3 JAR download, SSM access, and CloudWatch Agent logging/metrics.

- **User Data (in Launch Template) → ASG Instances**  
  On boot: installs Java + CloudWatch Agent, pulls JAR from S3, configures env vars, starts the app as systemd service.

- **ASG Instances → CloudWatch**  
  Sends application logs, system logs, and host metrics (CPU, memory, disk) via CloudWatch Agent.

- **ASG Instances → S3**  
  Pulls the application JAR artifact during instance launch.

- **SSM → ASG Instances**  
  Enables secure shell access via Session Manager without opening SSH ports.

  ## Related Modules

This module (`api_asg_alb`) is the production-oriented composition of lower-level building blocks. Choose based on environment, scaling needs, and separation of concerns:

| Module                     | Use Case                              | Key Components                          | Best For                     | Key Difference from `api_asg_alb`                              |
|----------------------------|---------------------------------------|-----------------------------------------|------------------------------|----------------------------------------------------------------|
| `api_asg_alb`              | Full scalable prod API deployment     | ALB + ASG + automatic TG attachment     | Staging / Production         | This module (combined ALB + scalable compute)                  |
| `api_common_alb`           | Public load balancer only             | ALB, Listener, Target Group, SG rules   | When compute is managed separately | Only the ALB part — no compute                                 |
| `api_compute_asg`          | Scalable compute only                 | Launch Template + ASG                   | When using custom ALB setup  | Only the compute part — requires separate ALB & TG             |
| `api_compute_ec2`          | Single-instance dev compute           | Single EC2 + user-data bootstrap        | Development                  | Fixed single instance, no scaling, manual TG attachment        |
| `api_network` (assumed)    | VPC + subnets foundation              | VPC, public/private subnets, base SGs   | All environments             | Provides networking foundation for this module                 |
| `api_alb_https` (future)   | Secure full stack                     | ALB + ACM cert + HTTPS + redirect       | Production security          | Adds HTTPS and redirect on top of this module                  |

### Quick Guidance

- **Use `api_asg_alb`** for staging and production — it delivers a complete, scalable, highly available API stack (load balancer + auto-scaling instances) with minimal configuration.
- **Use `api_compute_ec2`** in development — lower cost and simpler (single instance, manual target group registration).
- **Use `api_common_alb` + `api_compute_asg`** separately if you need more flexibility (e.g., multiple load balancers, custom routing rules, or different compute configurations).
- **Extend with `api_alb_https`** when ready for production security (add ACM certificate, HTTPS listener, and HTTP-to-HTTPS redirect).

This composition keeps your infrastructure modular and DRY while providing a clear, opinionated path from development to production-grade deployment.
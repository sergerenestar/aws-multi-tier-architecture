# api_asg_alb Terraform Module

This module provides a **complete, production-ready, scalable API deployment** on AWS by composing two lower-level modules:

- `api_common_alb` → public Application Load Balancer with target group and security group rules
- `api_compute_asg` → Auto Scaling Group of EC2 instances automatically registered to the ALB target group

It is the recommended pattern for staging and production environments where high availability, automatic scaling, rolling updates, and resilience are important.

It creates / composes:

- Internet-facing ALB in public subnets with HTTP listener
- Target group with health checks (default: Spring Boot Actuator `/actuator/health`)
- Security group rules allowing Internet → ALB → App instances only
- Auto Scaling Group in private subnets with configurable min/desired/max capacity
- Launch Template with user-data bootstrap (Java 17 Corretto, JAR download from S3, CloudWatch Agent, systemd service)
- Dynamic attachment of ASG instances to the target group

## Component Relationships

```markdown
# 📦 api_asg_alb — Component Relationships

This module represents the full scalable API stack (load balancer + auto-scaling compute).

## 🔗 Relationship Between Components

- **Internet → ALB Security Group**  
  Allows inbound HTTP (port 80 by default) from anywhere (0.0.0.0/0).

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
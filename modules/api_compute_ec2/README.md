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
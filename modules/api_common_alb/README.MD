# api_common_alb Terraform Module

This module provisions a public-facing **Application Load Balancer (ALB)** on AWS — the standard entry point for routing external traffic to your Spring Boot API running behind it (via `api_compute_ec2` or `api_compute_asg`).

It creates:

- Dedicated Security Group for the ALB (allows HTTP from anywhere)
- Internet-facing Application Load Balancer in public subnets
- HTTP listener that forwards traffic to the target group
- Target group (instance type) with configurable health checks
- Security group rule allowing ALB → application instances/ASG on the backend port

## Component Relationships

```markdown
# 📦 api_common_alb — Component Relationships

This module represents the public load-balancing and traffic-routing layer.

## 🔗 Relationship Between Components

- **Internet → ALB Security Group**  
  Allows inbound HTTP (port 80 by default) from anywhere (0.0.0.0/0).

- **ALB Security Group → ALB**  
  The ALB uses this security group to accept public traffic.

- **ALB → HTTP Listener**  
  The listener (port 80) is attached to the ALB and configured to forward requests.

- **HTTP Listener → Target Group**  
  All incoming traffic is forwarded to the target group.

- **Target Group → App Instances / ASG**  
  Registers EC2 instances (single or ASG) as targets; uses health checks to determine healthy routing.

- **ALB Security Group → App Security Group**  
  Adds an ingress rule to the app SG allowing traffic only from the ALB SG on var.app_port.

- **Public Subnets → ALB**  
  The ALB is placed in public subnets for internet accessibility (no public IP on instances).

  ## Related Modules

This module (`api_common_alb`) is part of a family of networking and load-balancing patterns. Choose or combine based on your traffic, security, and environment requirements:

| Module                     | Use Case                              | Key Components                          | Best For                     | Key Difference from `api_common_alb`                          |
|----------------------------|---------------------------------------|-----------------------------------------|------------------------------|----------------------------------------------------------------|
| `api_common_alb`           | Public HTTP/HTTPS entry point         | ALB, Listener, Target Group, SG rules   | All environments             | This module (basic public ALB + HTTP)                          |
| `api_compute_ec2`          | Single-instance dev compute           | EC2, user-data bootstrap                | Development                  | Registers manually to this module's target group               |
| `api_compute_asg`          | Scalable prod compute                 | ASG + Launch Template                   | Staging/Production           | Registers dynamically via `target_group_arns` to this module   |
| `api_network` (assumed)    | VPC + subnets foundation              | VPC, public/private subnets, base SGs   | All environments             | Provides `vpc_id`, `public_subnet_ids`, `app_sg_id` for this module |
| `api_alb_https` (future)   | Secure public entry point             | ALB + ACM cert + HTTPS listener + redirect | Production                | Adds HTTPS, certificate, and HTTP→HTTPS redirect               |
| `api_waf` (future)         | Protected public entry point          | WAF Web ACL attached to ALB             | Production (security-focused)| Adds bot protection, SQLi/XSS rules on top of this module      |

### Quick Guidance

- **Use `api_common_alb`** as the standard public-facing load balancer for development, staging, and production.
- **Pair with `api_compute_ec2`** during early development — simple manual registration to the target group.
- **Pair with `api_compute_asg`** for production — automatic scaling and dynamic target registration.
- **Extend with `api_alb_https`** when HTTPS is required (add certificate and redirect logic).
- **Add `api_waf`** on top for production-grade security (rate limiting, bot mitigation, OWASP rules).

This modular approach keeps the load-balancing layer consistent while allowing compute and security to scale independently.
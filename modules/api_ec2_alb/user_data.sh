#!/bin/bash

# ------------------------------------------------------------
# Geotech API EC2 Bootstrap Script (with Observability)
# ------------------------------------------------------------
# Purpose:
#   - Prepare Amazon Linux 2023 instance
#   - Install Java runtime + AWS CLI
#   - Install & configure CloudWatch Agent for logs/metrics
#   - Download application JAR from S3
#   - Inject environment configuration
#   - Register and start systemd service
# ------------------------------------------------------------

set -euo pipefail

# ------------------------------------------------------------
# 0️⃣ Helper: get instance metadata (IMDSv2)
# ------------------------------------------------------------
get_imds_token() {
  curl -sS -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"
}

IMDS_TOKEN="$(get_imds_token || true)"
imds_get() {
  local path="$1"
  curl -sS -H "X-aws-ec2-metadata-token: ${IMDS_TOKEN}" \
    "http://169.254.169.254/latest/${path}"
}

INSTANCE_ID="$(imds_get meta-data/instance-id || echo "unknown")"
AZ="$(imds_get meta-data/placement/availability-zone || echo "unknown")"
REGION="${AZ::-1}" # simple: us-east-1a -> us-east-1

# ------------------------------------------------------------
# 1️⃣ System Preparation
# ------------------------------------------------------------
dnf -y update

# Java + AWS CLI for artifact download
dnf -y install java-17-amazon-corretto awscli

# ------------------------------------------------------------
# 2️⃣ Install CloudWatch Agent (Observability)
# ------------------------------------------------------------
# Amazon Linux 2023 supports amazon-cloudwatch-agent via dnf.
# This agent can ship:
#   - logs (files)
#   - metrics (CPU/mem/disk, etc.)
dnf -y install amazon-cloudwatch-agent

# ------------------------------------------------------------
# 3️⃣ Application Directory Setup
# ------------------------------------------------------------
mkdir -p /opt/app
cd /opt/app

# Create a dedicated log directory for the app
mkdir -p /var/log/geotech-api
chmod 755 /var/log/geotech-api

# ------------------------------------------------------------
# 4️⃣ Download Application Artifact
# ------------------------------------------------------------
# EC2 instance role must allow s3:GetObject on the artifact bucket/key.
aws s3 cp "s3://${APP_S3_BUCKET}/${APP_S3_KEY}" /opt/app/app.jar

# ------------------------------------------------------------
# 5️⃣ Create Environment Configuration File
# ------------------------------------------------------------
# NOTE: Avoid putting secrets directly in user-data if possible.
# Prefer pulling DB_PASS from SSM Parameter Store or Secrets Manager in prod.
cat > /opt/app/app.env <<EOF
SPRING_PROFILES_ACTIVE=prod
SERVER_PORT=${APP_PORT}

# Database Configuration (Private RDS)
SPRING_DATASOURCE_URL=jdbc:mysql://${DB_HOST}:3306/${DB_NAME}?useSSL=true&serverTimezone=UTC
SPRING_DATASOURCE_USERNAME=${DB_USER}
SPRING_DATASOURCE_PASSWORD=${DB_PASS}

# CORS Configuration
APP_CORS_ALLOWED_ORIGINS=${CORS_ALLOWED_ORIGINS}

# Optional: allow overriding log group names from Terraform env vars
CW_LOG_GROUP_APP=${CW_LOG_GROUP_APP:-/aws/${NAME:-geotech}/${ENVIRONMENT:-prod}/app}
CW_LOG_GROUP_SYS=${CW_LOG_GROUP_SYS:-/aws/${NAME:-geotech}/${ENVIRONMENT:-prod}/system}
EOF

# Load the env vars for use in this script (log group names, etc.)
# shellcheck disable=SC1091
source /opt/app/app.env || true

# ------------------------------------------------------------
# 6️⃣ Create systemd Service (write logs to file)
# ------------------------------------------------------------
# Key change for observability:
#   - We redirect stdout/stderr into /var/log/geotech-api/geotech-api.log
#   - CloudWatch Agent will ship that log file to CloudWatch Logs
cat > /etc/systemd/system/geotech-api.service <<'EOF'
[Unit]
Description=Geotech Spring Boot API
After=network.target

[Service]
WorkingDirectory=/opt/app
EnvironmentFile=/opt/app/app.env

# Write application logs to a file so CloudWatch Agent can ship them
ExecStart=/bin/bash -c '/usr/bin/java -jar /opt/app/app.jar >> /var/log/geotech-api/geotech-api.log 2>&1'

Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

# ------------------------------------------------------------
# 7️⃣ Configure CloudWatch Agent
# ------------------------------------------------------------
# This config ships:
#   - app log file
#   - /var/log/messages and /var/log/secure for basic host troubleshooting
# And publishes basic system metrics (CPU/mem/disk).
#
# IAM REQUIRED on instance role:
#   logs:CreateLogGroup, logs:CreateLogStream, logs:PutLogEvents, logs:DescribeLogStreams
#   cloudwatch:PutMetricData
# (Optional) ec2:DescribeTags if you enrich metadata
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "agent": {
    "region": "${REGION}",
    "metrics_collection_interval": 60,
    "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
  },
  "metrics": {
    "append_dimensions": {
      "InstanceId": "${INSTANCE_ID}",
      "AutoScalingGroupName": "\${aws:AutoScalingGroupName}"
    },
    "metrics_collected": {
      "cpu": { "measurement": ["cpu_usage_idle","cpu_usage_iowait","cpu_usage_user","cpu_usage_system"], "metrics_collection_interval": 60, "totalcpu": true },
      "mem": { "measurement": ["mem_used_percent"], "metrics_collection_interval": 60 },
      "disk": { "measurement": ["used_percent"], "metrics_collection_interval": 60, "resources": ["*"] }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/geotech-api/geotech-api.log",
            "log_group_name": "${CW_LOG_GROUP_APP}",
            "log_stream_name": "{instance_id}/geotech-api",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/messages",
            "log_group_name": "${CW_LOG_GROUP_SYS}",
            "log_stream_name": "{instance_id}/messages",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/secure",
            "log_group_name": "${CW_LOG_GROUP_SYS}",
            "log_stream_name": "{instance_id}/secure",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
EOF

# ------------------------------------------------------------
# 8️⃣ Activate Services
# ------------------------------------------------------------
systemctl daemon-reload

# Start and enable your API
systemctl enable geotech-api
systemctl start geotech-api

# Start and enable CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

systemctl enable amazon-cloudwatch-agent

echo "Bootstrap complete: app + CloudWatch agent running."
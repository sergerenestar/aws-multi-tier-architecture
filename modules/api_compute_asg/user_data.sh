#!/bin/bash
set -euo pipefail

# ------------------------------------------------------------
# ASG Bootstrap (Amazon Linux 2023) + Observability
# ------------------------------------------------------------
# Terraform injects:
#   NAME, ENVIRONMENT
#   APP_S3_BUCKET, APP_S3_KEY
#   APP_PORT, CORS_ALLOWED_ORIGINS
#   DB_HOST, DB_NAME, DB_USER, DB_PASS
#   CW_LOG_GROUP_APP, CW_LOG_GROUP_SYS
# ------------------------------------------------------------

NAME="${NAME}"
ENVIRONMENT="${ENVIRONMENT}"

APP_S3_BUCKET="${APP_S3_BUCKET}"
APP_S3_KEY="${APP_S3_KEY}"

APP_PORT="${APP_PORT}"
CORS_ALLOWED_ORIGINS="${CORS_ALLOWED_ORIGINS}"

DB_HOST="${DB_HOST}"
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
DB_PASS="${DB_PASS}"

CW_LOG_GROUP_APP="${CW_LOG_GROUP_APP}"
CW_LOG_GROUP_SYS="${CW_LOG_GROUP_SYS}"

# ---- IMDSv2 (region + instance_id) ----
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
REGION="${AZ::-1}"

# ---- packages ----
dnf -y update
dnf -y install java-17-amazon-corretto awscli amazon-cloudwatch-agent

# ---- app dirs ----
mkdir -p /opt/app
mkdir -p /var/log/geotech-api
chmod 755 /var/log/geotech-api
cd /opt/app

# ---- download jar ----
aws s3 cp "s3://${APP_S3_BUCKET}/${APP_S3_KEY}" /opt/app/app.jar

# ---- env file for Spring ----
cat > /opt/app/app.env <<EOF
SPRING_PROFILES_ACTIVE=${ENVIRONMENT}
SERVER_PORT=${APP_PORT}

SPRING_DATASOURCE_URL=jdbc:mysql://${DB_HOST}:3306/${DB_NAME}?useSSL=true&serverTimezone=UTC
SPRING_DATASOURCE_USERNAME=${DB_USER}
SPRING_DATASOURCE_PASSWORD=${DB_PASS}

APP_CORS_ALLOWED_ORIGINS=${CORS_ALLOWED_ORIGINS}

CW_LOG_GROUP_APP=${CW_LOG_GROUP_APP}
CW_LOG_GROUP_SYS=${CW_LOG_GROUP_SYS}
EOF

# ---- systemd service ----
cat > /etc/systemd/system/geotech-api.service <<'EOF'
[Unit]
Description=Geotech Spring Boot API
After=network.target

[Service]
WorkingDirectory=/opt/app
EnvironmentFile=/opt/app/app.env
ExecStart=/bin/bash -c '/usr/bin/java -jar /opt/app/app.jar >> /var/log/geotech-api/geotech-api.log 2>&1'
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

# ---- CloudWatch agent config ----
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "agent": {
    "region": "${REGION}",
    "metrics_collection_interval": 60
  },
  "metrics": {
    "append_dimensions": {
      "InstanceId": "${INSTANCE_ID}",
      "AutoScalingGroupName": "\${aws:AutoScalingGroupName}"
    },
    "metrics_collected": {
      "cpu": { "measurement": ["cpu_usage_user","cpu_usage_system","cpu_usage_iowait"], "totalcpu": true, "metrics_collection_interval": 60 },
      "mem": { "measurement": ["mem_used_percent"], "metrics_collection_interval": 60 },
      "disk": { "measurement": ["used_percent"], "resources": ["*"], "metrics_collection_interval": 60 }
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

# ---- start services ----
systemctl daemon-reload
systemctl enable geotech-api
systemctl start geotech-api

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

systemctl enable amazon-cloudwatch-agent
echo "ASG instance bootstrap complete."
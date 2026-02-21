#!/bin/bash

# ------------------------------------------------------------
# Geotech API EC2 Bootstrap Script
# ------------------------------------------------------------
# Purpose:
#   - Prepare Amazon Linux 2023 instance
#   - Install Java runtime + AWS CLI
#   - Download application JAR from S3
#   - Inject environment configuration
#   - Register and start systemd service
# ------------------------------------------------------------

# Exit immediately if any command fails
set -e

# ------------------------------------------------------------
# 1️⃣ System Preparation
# ------------------------------------------------------------

# Update system packages to latest security patches
dnf -y update

# Install Amazon Corretto 17  and AWS CLI (used to download application artifact from S3)
dnf -y install java-17-amazon-corretto awscli


# ------------------------------------------------------------
# 2️⃣ Application Directory Setup
# ------------------------------------------------------------

# Create application directory
mkdir -p /opt/app
cd /opt/app


# ------------------------------------------------------------
# 3️⃣ Download Application Artifact
# ------------------------------------------------------------

# Download compiled Spring Boot JAR from S3.
# EC2 instance IAM role must allow s3:GetObject for this bucket/key.
aws s3 cp "s3://${APP_S3_BUCKET}/${APP_S3_KEY}" app.jar


# ------------------------------------------------------------
# 4️⃣ Create Environment Configuration File
# ------------------------------------------------------------
# Externalize configuration from application binary.
# This avoids hardcoding secrets in the JAR.
# Spring Boot reads these variables via EnvironmentFile.

cat > /opt/app/app.env <<EOF
SPRING_PROFILES_ACTIVE=prod
SERVER_PORT=${APP_PORT}

# Database Configuration (Private RDS)
SPRING_DATASOURCE_URL=jdbc:mysql://${DB_HOST}:3306/${DB_NAME}?useSSL=true&serverTimezone=UTC
SPRING_DATASOURCE_USERNAME=${DB_USER}
SPRING_DATASOURCE_PASSWORD=${DB_PASS}

# CORS Configuration
APP_CORS_ALLOWED_ORIGINS=${CORS_ALLOWED_ORIGINS}
EOF


# ------------------------------------------------------------
# 5️⃣ Create systemd Service
# ------------------------------------------------------------
# Register the application as a system service so it:
#   - Starts automatically on boot
#   - Restarts on failure
#   - Runs in background
#   - Is manageable via systemctl

cat > /etc/systemd/system/geotech-api.service <<'EOF'
[Unit]
Description=Geotech Spring Boot API
After=network.target

[Service]
WorkingDirectory=/opt/app
EnvironmentFile=/opt/app/app.env
ExecStart=/usr/bin/java -jar /opt/app/app.jar
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF


# ------------------------------------------------------------
# 6️⃣ Activate Service
# ------------------------------------------------------------

# Reload systemd to detect new service file
systemctl daemon-reload

# Enable service to start on instance reboot
systemctl enable geotech-api

# Start application immediately
systemctl start geotech-api
#!/usr/bin/env bash

set -e

BASE_DIR="INFRA"

# Directories
DIRS=(
  "$BASE_DIR/bootstrap"
  "$BASE_DIR/env"
  "$BASE_DIR/env/modules"
  "$BASE_DIR/env/modules/network"
  "$BASE_DIR/env/modules/frontend_s3_cf"
  "$BASE_DIR/env/modules/api_ec2_alb"
  "$BASE_DIR/env/modules/rds_mysql"
)

# Files
FILES=(
  # bootstrap
  "$BASE_DIR/bootstrap/artifacts_bucket.tf"
  "$BASE_DIR/bootstrap/main.tf"
  "$BASE_DIR/bootstrap/outputs.tf"
  "$BASE_DIR/bootstrap/providers.tf"
  "$BASE_DIR/bootstrap/versions.tf"

  # env root
  "$BASE_DIR/env/backend.hcl"
  "$BASE_DIR/env/backend.tf"
  "$BASE_DIR/env/main.tf"
  "$BASE_DIR/env/outputs.tf"
  "$BASE_DIR/env/providers.tf"
  "$BASE_DIR/env/terraform.tfvars"
  "$BASE_DIR/env/variables.tf"
  "$BASE_DIR/env/versions.tf"

  # modules/network
  "$BASE_DIR/env/modules/network/main.tf"
  "$BASE_DIR/env/modules/network/outputs.tf"
  "$BASE_DIR/env/modules/network/variables.tf"

  # modules/frontend_s3_cf
  "$BASE_DIR/env/modules/frontend_s3_cf/main.tf"
  "$BASE_DIR/env/modules/frontend_s3_cf/outputs.tf"
  "$BASE_DIR/env/modules/frontend_s3_cf/variables.tf"

  # modules/api_ec2_alb
  "$BASE_DIR/env/modules/api_ec2_alb/main.tf"
  "$BASE_DIR/env/modules/api_ec2_alb/outputs.tf"
  "$BASE_DIR/env/modules/api_ec2_alb/user_data.sh"
  "$BASE_DIR/env/modules/api_ec2_alb/variables.tf"

  # modules/rds_mysql
  "$BASE_DIR/env/modules/rds_mysql/main.tf"
  "$BASE_DIR/env/modules/rds_mysql/outputs.tf"
  "$BASE_DIR/env/modules/rds_mysql/variables.tf"
)

echo "Creating directories..."
for d in "${DIRS[@]}"; do
  mkdir -p "$d"
done

echo "Creating files..."
for f in "${FILES[@]}"; do
  touch "$f"
done

echo "Terraform infrastructure structure created successfully."

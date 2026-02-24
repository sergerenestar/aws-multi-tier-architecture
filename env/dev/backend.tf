terraform {
  backend "s3" {
    bucket         = "YOUR-TFSTATE-BUCKET"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "YOUR-TFLOCK-TABLE"
    encrypt        = true
  }
}
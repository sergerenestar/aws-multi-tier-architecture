provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# For WAF (CLOUDFRONT scope) + ACM certs for CloudFront
provider "aws" {
  alias   = "use1"
  region  = "us-east-1"
  profile = var.aws_profile
}

provider "random" {}

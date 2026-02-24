output "frontend_bucket_name" {
  value = module.frontend.frontend_bucket_name
}

output "cloudfront_domain_name" {
  value = module.frontend.cloudfront_domain_name
}

output "cloudfront_distribution_id" {
  value = module.frontend.cloudfront_distribution_id
}

output "api_url" {
  value = "http://${module.api.alb_dns_name}"
}

output "frontend_url" {
  value = "https://${module.frontend.cloudfront_domain_name}"
}

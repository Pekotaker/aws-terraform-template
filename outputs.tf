output "project" {
  description = "Project name"
  value       = local.project
}
output "region" {
  description = "AWS region"
  value       = local.region
  
}
output "azs" {
  description = "Availability zones"
  value       = local.azs
}
output "primary_az" {
  description = "Primary availability zone"
  value       = local.primary_az
}
output "aws_profile" {
  description = "AWS profile"
  value       = local.aws_profile
}
output "s3_private_bucket_name" {
  description = "Private S3 bucket name"
  value       = module.s3.private_bucket.s3_bucket_bucket_domain_name
}
output "s3_public_bucket_name" {
  description = "Public S3 bucket name"
  value       = module.s3.public_bucket.s3_bucket_bucket_domain_name
}
output "s3_cdn_domain_name" {
  value       = module.s3.cdn.cloudfront_distribution_domain_name
}
output "lb_url" {
  description = "URL of load balancer"
  value       = module.autoscaling.output.alb.dns_name
}
output"bastion_public_ip" {
  description = "Bastion public IP"
  value       = module.bastion.output.public_ip
}
output "bastion_hostname" {
  description = "Bastion hostname"
  value       = module.bastion.output.public_dns
  
}
output "efs_dns_name" {
  description = "EFS DNS name"
  value       = module.efs.output.dns_name
}
output "db_host" {
  description = "Database host"
  value       = module.postgres.output.db_instance_endpoint
  sensitive   = false # should be true
}
output "db_name" {
  description = "Database name"
  value       = module.postgres.output.db_instance_name
  sensitive   = false # should be true
}
output "db_username" {
  description = "Database administrator username"
  value       = module.postgres.output.db_instance_username
  sensitive   = false # should be true
}
output "db_password" {
  description = "Database administrator password"
  value       = module.postgres.output.db_instance_password
  sensitive   = false # should be true
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = local.ecs_cluster_name
}
output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_name
}
output "ecs_service_name" {

  value       = module.ecs.ecs_service_name
}
output "ecs_task_definition" {
  value       = module.ecs.ecs_task_definition
}
output "container_port" {
  value       = local.backend_port
}


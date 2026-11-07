# Public address of the application
output "application_url" {
  description = "HTTP address of the load balancer"
  value       = var.enable_application ? "http://${aws_lb.app[0].dns_name}" : null
}

# IDs of both application servers
output "ec2_instance_ids" {
  description = "EC2 instances running Flask"
  value       = aws_instance.app[*].id
}

# Private RDS hostname
output "rds_endpoint" {
  description = "Private PostgreSQL RDS hostname"
  value       = aws_db_instance.main.address
}

# Name of our private deployment bucket
output "deployment_bucket" {
  description = "S3 bucket containing app.zip"
  value       = aws_s3_bucket.deployment.bucket
}

# CloudWatch dashboard name
output "monitoring_dashboard" {
  description = "CloudWatch monitoring dashboard"
  value       = var.enable_application ? aws_cloudwatch_dashboard.main[0].dashboard_name : null
}


output "rds_master_secret_arn" {
  description = "ARN of the RDS master credentials secret"
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}


output "redis_endpoint" {
  description = "TLS Redis endpoint for application caching"
  value = var.enable_redis_cache ? (
    "rediss://${aws_elasticache_replication_group.redis[0].primary_endpoint_address}:6379"
  ) : null
}

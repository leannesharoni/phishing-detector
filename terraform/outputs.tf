# Public address of the application
output "application_url" {
  description = "HTTP address of the load balancer"
  value       = "http://${aws_lb.app.dns_name}"
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
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

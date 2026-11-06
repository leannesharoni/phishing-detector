# Private S3 bucket for the application package
resource "aws_s3_bucket" "deployment" {
  bucket_prefix = "phishing-deploy-"
  force_destroy = true

  tags = {
    Name = "phishing-deployment"
  }
}

# Explicitly block public access
resource "aws_s3_bucket_public_access_block" "deployment" {
  bucket = aws_s3_bucket.deployment.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# Encrypt objects stored in the bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "deployment" {
  bucket = aws_s3_bucket.deployment.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Upload the application ZIP
resource "aws_s3_object" "app_package" {
  bucket       = aws_s3_bucket.deployment.id
  key          = "app.zip"
  source       = "${path.module}/../deploy/app.zip"
  source_hash  = filemd5("${path.module}/../deploy/app.zip")
  content_type = "application/zip"

  depends_on = [
    aws_s3_bucket_public_access_block.deployment,
    aws_s3_bucket_server_side_encryption_configuration.deployment
  ]
}

# Get the latest Amazon Linux 2023 AMI
data "aws_ssm_parameter" "amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Two EC2 application servers
resource "aws_instance" "app" {
  count = 2

  ami                  = data.aws_ssm_parameter.amazon_linux.value
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.app.name


  user_data = templatefile("${path.module}/user_data.sh", {
    bucket_name = aws_s3_bucket.deployment.bucket
    aws_region  = "eu-north-1"

    service_content_b64 = base64encode(templatefile(
      "${path.module}/phishing-detector.service",
      {
        db_secret_arn = var.app_db_secret_arn
        db_host       = aws_db_instance.main.address
      }
    ))

    cwagent_config_b64 = filebase64("${path.module}/cloudwatch-agent.json")
  })

  subnet_id = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ][count.index]

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  associate_public_ip_address = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "phishing-app-${count.index + 1}"
  }


  depends_on = [
    aws_s3_object.app_package,
    aws_iam_role_policy.read_app_package,
    aws_iam_role_policy.write_logs,
    aws_iam_role_policy.read_db_secret
  ]
}
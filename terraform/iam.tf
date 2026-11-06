# Role that EC2 instances are allowed to assume
resource "aws_iam_role" "app" {
  name = "phishing-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "phishing-ec2-role"
  }
}

# Permission to read only our application ZIP
resource "aws_iam_role_policy" "read_app_package" {
  name = "phishing-read-app-package"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = aws_s3_object.app_package.arn
      }
    ]
  })
}

# Connect the IAM role to EC2
resource "aws_iam_instance_profile" "app" {
  name = "phishing-ec2-profile"
  role = aws_iam_role.app.name
}


# Allow EC2 to write logs to our CloudWatch log groups
resource "aws_iam_role_policy" "write_logs" {
  name = "phishing-write-cloudwatch-logs"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]

        Resource = [
          "${aws_cloudwatch_log_group.setup.arn}:*",
          "${aws_cloudwatch_log_group.app_errors.arn}:*"
        ]
      },
      {
        Effect = "Allow"

        Action = [
          "logs:DescribeLogGroups"
        ]

        Resource = "*"
      }
    ]
  })
}


# Allow EC2 to read only the application database secret
resource "aws_iam_role_policy" "read_db_secret" {
  name = "phishing-read-db-secret"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = var.app_db_secret_arn
      }
    ]
  })
}


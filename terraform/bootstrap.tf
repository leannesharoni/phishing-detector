variable "enable_db_bootstrap" {
  description = "Create a temporary EC2 instance for database setup"
  type        = bool
  default     = false
}

resource "aws_instance" "db_bootstrap" {
  count = var.enable_db_bootstrap ? 1 : 0


  ami                         = data.aws_ssm_parameter.amazon_linux.value
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_a.id
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.bootstrap.id
  ]

  iam_instance_profile = aws_iam_instance_profile.bootstrap.name

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.bootstrap_ssm,
    aws_route_table_association.public_a,
    aws_vpc_security_group_egress_rule.bootstrap_https,
    aws_vpc_security_group_egress_rule.bootstrap_to_db,
    aws_vpc_security_group_ingress_rule.db_from_bootstrap
  ]

  tags = {
    Name = "phishing-db-bootstrap-temporary"
  }
}

output "db_bootstrap_instance_id" {
  value = var.enable_db_bootstrap ? aws_instance.db_bootstrap[0].id : null
}


resource "aws_iam_role" "bootstrap" {
  name = "phishing-bootstrap-role"

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
}

resource "aws_iam_role_policy_attachment" "bootstrap_ssm" {
  role       = aws_iam_role.bootstrap.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bootstrap" {
  name = "phishing-bootstrap-profile"
  role = aws_iam_role.bootstrap.name
}

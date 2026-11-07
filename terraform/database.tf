# Private subnets where RDS may be placed
resource "aws_db_subnet_group" "main" {
  name = "phishing-db-subnets"

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "phishing-db-subnets"
  }
}

# Shared PostgreSQL database
resource "aws_db_instance" "main" {
  identifier = "phishing-postgres"

  engine                   = "postgres"
  engine_version           = "17.11"
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"
  instance_class           = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp2"
  storage_encrypted = true

  db_name  = "phishing_detector"
  username = "phishing_admin"

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  publicly_accessible = false
  port                = 5432
  multi_az            = false

  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true

  tags = {
    Name = "phishing-postgres"
  }
}

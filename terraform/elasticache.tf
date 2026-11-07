# Private subnets for the Redis cache.
resource "aws_elasticache_subnet_group" "redis" {
  count = var.enable_redis_cache ? 1 : 0

  name = "phishing-redis-subnets"

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
}

# Security group for the Redis cache.
resource "aws_security_group" "redis" {
  count = var.enable_redis_cache ? 1 : 0

  name        = "phishing-redis-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "phishing-redis-sg"
  }
}

# Allow Redis traffic only from the application servers.
resource "aws_vpc_security_group_ingress_rule" "redis_from_app" {
  count = var.enable_redis_cache ? 1 : 0

  security_group_id            = aws_security_group.redis[0].id
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
}

# Allow application servers to connect to Redis.
resource "aws_vpc_security_group_egress_rule" "app_to_redis" {
  count = var.enable_redis_cache ? 1 : 0

  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.redis[0].id
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
}

# Single-node Redis cache with encryption enabled.
resource "aws_elasticache_replication_group" "redis" {
  count = var.enable_redis_cache ? 1 : 0

  replication_group_id = "phishing-detector-redis"
  description          = "Redis cache for phishing scan results"

  engine             = "redis"
  engine_version     = "7.1"
  node_type          = "cache.t3.micro"
  num_cache_clusters = 1
  port               = 6379

  subnet_group_name  = aws_elasticache_subnet_group.redis[0].name
  security_group_ids = [aws_security_group.redis[0].id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  automatic_failover_enabled = false

  tags = {
    Name = "phishing-detector-redis"
  }
}

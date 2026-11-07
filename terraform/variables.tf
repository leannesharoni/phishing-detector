variable "app_db_secret_arn" {
  description = "ARN of the application database secret"
  type        = string
  default     = ""
}

variable "enable_application" {
  description = "Deploy application servers and related resources"
  type        = bool
  default     = false
}


variable "enable_redis_cache" {
  description = "Enable the optional ElastiCache Redis bonus"
  type        = bool
  default     = false
}

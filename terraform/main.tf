
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "eu-north-1"
}

variable "aws_profile" {
  description = "AWS CLI profile used for deployment"
  type        = string
  default     = null
}

variable "aws_account_id" {
  description = "AWS account ID allowed for deployment"
  type        = string
  default     = null
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  allowed_account_ids = var.aws_account_id != null ? [var.aws_account_id] : null
}

######################################
# Real file
#######################################

variable "role_name" {
  description = "Name of the IAM role for AWS Batch"
  type        = string
}

variable "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group used by AWS Batch jobs"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket used by Batch jobs"
  type        = string
}

variable "aws_region" {
  description = "AWS region used for EBS encryption context"
  type        = string
}


##################################################################

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "CIDR block for the Batch VPC"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks for private subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones for private subnets"
}

variable "batch_instance_type" {
  type        = list(string)
  description = "List of instance types for Batch compute resources"
  default     = ["m5.large"]
}

/*
#################################################
# Terraform Mock Provider Fake File for Testing
#################################################

variable "availability_zones" {
  description = "List of availability zones for private subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "aws_region" {
  description = "AWS region used for EBS encryption context"
  type        = string
  default     = "us-east-1"
}

variable "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group used by AWS Batch jobs"
  type        = string
  default     = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/batch/job"
}

variable "role_name" {
  description = "Name of the IAM role for AWS Batch"
  type        = string
  default     = "batch-role"
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket used by Batch jobs"
  type        = string
  default     = "arn:aws:s3:::example-bucket"
}
*/
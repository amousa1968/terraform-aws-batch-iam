# terraform-aws-batch-iam
Terraform module to implement IAM roles and policies for AWS Batch least-privilege 

## Terraform Mock Provider Fake File for Testing
To create a mock provider configuration and variable definitions that would allow you to run terraform plan without errors, you can use the following approach:

## Create a mock.tf file
```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
```
## Create a variables.tf file with default values
```
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
```

## Create a terraform.tfvars file (optional)
```
availability_zones = ["us-east-1a", "us-east-1b"]
aws_region        = "us-east-1"
cloudwatch_log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/batch/job"
role_name         = "batch-role"
s3_bucket_arn     = "arn:aws:s3:::example-bucket"
```
## Usage
With these files in place, you can run:

```
terraform init
terraform validate
```
<img width="567" alt="image" src="https://github.com/user-attachments/assets/ea2cf687-3f9a-4584-9f6f-1c0e2ca3686a" />


<img width="463" alt="image" src="https://github.com/user-attachments/assets/6ab9f07b-e089-46c9-b891-6a9f1ed049c7" />



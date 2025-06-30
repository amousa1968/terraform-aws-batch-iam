# ----------------------
# IAM roles and policies
# ----------------------

resource "aws_iam_role" "batch_service_role" {
  name = var.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "batch.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "batch_custom_policy" {
  name        = "${var.role_name}-policy"
  description = "Least privilege IAM policy for AWS Batch compute with EBS, S3 encryption, and TLS enforced"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      # Allow CloudWatch Logs
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = var.cloudwatch_log_group_arn
      },

      # EBS encryption (via KMS key)
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateVolume",
          "ec2:AttachVolume",
          "ec2:DeleteVolume",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeAttribute",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:Decrypt"
        ],
        Resource = "*",
        Condition = {
          "Bool" : {
            "kms:ViaService" : "ec2.${var.aws_region}.amazonaws.com"
          }
        }
      },

      # S3 access with encryption enforced
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = "${var.s3_bucket_arn}/*",
        Condition = {
          "StringEquals" : {
            "s3:x-amz-server-side-encryption" : "AES256"
          }
        }
      },

      # TLS enforcement (HTTPS)
      {
        Effect   = "Deny",
        Action   = "s3:*",
        Resource = "*",
        Condition = {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      },

      # ECS tasks support (used by Batch under the hood)
      {
        Effect = "Allow",
        Action = [
          "ecs:RunTask",
          "ecs:DescribeTasks",
          "ecs:StopTask"
        ],
        Resource = "*"
      },

      # EC2 network configuration for compute environments
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "batch_attach_policy" {
  role       = aws_iam_role.batch_service_role.name
  policy_arn = aws_iam_policy.batch_custom_policy.arn
}


#############################################################

# ----------------------
# VPC
# ----------------------
resource "aws_vpc" "batch_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "batch-vpc"
  }
}

# ----------------------
# Private Subnets
# ----------------------
resource "aws_subnet" "private_subnets" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.batch_vpc.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "batch-private-${count.index}"
  }
}

# ----------------------
# Network ACL
# ----------------------
resource "aws_network_acl" "batch_acl" {
  vpc_id = aws_vpc.batch_vpc.id
  tags = {
    Name = "batch-nacl"
  }
}

# Allow all egress
resource "aws_network_acl_rule" "egress_allow_all" {
  network_acl_id = aws_network_acl.batch_acl.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

# Allow ingress from VPC only
resource "aws_network_acl_rule" "ingress_allow_internal" {
  network_acl_id = aws_network_acl.batch_acl.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

# ----------------------
# Security Group
# ----------------------
resource "aws_security_group" "batch_sg" {
  name        = "batch-sg"
  description = "Security group for AWS Batch compute environment"
  vpc_id      = aws_vpc.batch_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "batch-sg"
  }
}

# ----------------------------------------
# Batch Compute Environment (EC2 instance)
# -----------------------------------------
resource "aws_batch_compute_environment" "batch_ce" {
  name = "batch-compute-env"

  compute_resources {
    type               = "EC2"
    instance_role      = aws_iam_role.batch_service_role.arn
    instance_type      = var.batch_instance_type
    min_vcpus          = 0
    max_vcpus          = 16
    desired_vcpus      = 0
    subnets            = aws_subnet.private_subnets[*].id
    security_group_ids = [aws_security_group.batch_sg.id]
    #    instance_role       = aws_iam_instance_profile.batch_instance_profile.arn
  }
  service_role = aws_iam_role.batch_service_role.arn
  type         = "MANAGED"
}

# ----------------------
# Instance Profile (used by compute environment)
# ----------------------
resource "aws_iam_instance_profile" "batch_instance_profile" {
  name = "batch-ec2-instance-profile"
  role = aws_iam_role.batch_service_role.name
}


######################################################################################

# -----------------------------------------------
# CloudTrail to log AWS Batch API calls
# -----------------------------------------------
resource "aws_cloudtrail" "batch_trail" {
  name                          = "batch-api-activity"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  event_selector {
    read_write_type           = "All"
    include_management_events = true
    data_resource {
      #      type   = "AWS::Batch::Job"
      #      values = ["arn:aws:batch"]
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3"]

    }
  }

  tags = {
    Name = "batch-trail"
  }
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = "batch-cloudtrail-logs-${random_id.bucket_id.hex}"
  force_destroy = true

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name = "batch-cloudtrail-logs"
  }
}

resource "random_id" "bucket_id" {
  byte_length = 4
}

# -------------------------------
# ECR image scanning configuration
# -------------------------------
resource "aws_ecr_repository" "batch_job_repo" {
  name                 = "batch-job-container"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "batch-job-repo"
  }
}

# Optional: Allow scanning results retrieval
resource "aws_iam_policy" "ecr_scan_read_policy" {
  name        = "BatchECRScanRead"
  description = "Allow Batch to read ECR image scan results"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:DescribeImageScanFindings",
          "ecr:BatchCheckLayerAvailability",
          "ecr:DescribeImages"
        ],
        Resource = aws_ecr_repository.batch_job_repo.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ecr_scan_policy" {
  role       = aws_iam_role.batch_service_role.name
  policy_arn = aws_iam_policy.ecr_scan_read_policy.arn
}

output "batch_role_arn" {
  description = "ARN of the IAM role used by AWS Batch"
  value       = aws_iam_role.batch_service_role.arn
}

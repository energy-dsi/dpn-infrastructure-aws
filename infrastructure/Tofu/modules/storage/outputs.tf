output "bucket_name" {
  description = "Name of the private encrypted data bucket."
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "ARN of the private encrypted data bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_id" {
  description = "ID of the private encrypted data bucket."
  value       = aws_s3_bucket.this.id
}

output "application_bucket_name" {
  value = aws_s3_bucket.application.bucket
}

output "application_bucket_arn" {
  value = aws_s3_bucket.application.arn
}
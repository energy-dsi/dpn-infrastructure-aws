output "file_system_id" {
  value = aws_efs_file_system.this.id
}

output "file_system_arn" {
  value = aws_efs_file_system.this.arn
}

output "security_group_id" {
  value = aws_security_group.efs.id
}

output "dns_name" {
  description = "Regional EFS DNS name."
  value       = aws_efs_file_system.this.dns_name
}

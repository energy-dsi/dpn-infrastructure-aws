output "iam_role_arn" {
  value = aws_iam_role.this.arn
}

output "iam_policy_arn" {
  value = aws_iam_policy.this.arn
}

output "service_account_name" {
  value = "aws-load-balancer-controller"
}

output "service_account_namespace" {
  value = "platform"
}
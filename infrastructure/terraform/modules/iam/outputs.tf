output "eks_admin_role_arn" {
  description = "EKS admin role ARN"
  value       = aws_iam_role.eks_admin.arn
}
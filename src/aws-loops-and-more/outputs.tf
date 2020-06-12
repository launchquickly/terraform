output "neo_arn_count2" {
    value = aws_iam_user.count2[0].arn
    description = "The ARN for user Neo"
}

output "all_arns_count2" {
    value = "aws_iam_user.count2[*].arn
    description = "The ARN for all users"
}
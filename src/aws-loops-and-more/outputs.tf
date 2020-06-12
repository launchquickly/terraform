output "neo_arn_count2" {
    value = aws_iam_user.count2[0].arn
    description = "The ARN for user Neo"
}

output "all_arns_count2" {
    value = aws_iam_user.count2[*].arn
    description = "The ARN for all users"
}

output "all_users" {
    value = aws_iam_user.foreach1
}

output "all_arns_foreach1" {
    value = values(aws_iam_user.foreach1)[*].arn
    description = "The ARN for all users"
}

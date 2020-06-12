resource "aws_iam_user" "count1" {
  count = 3
  name  = "neo.${count.index}"
}

resource "aws_iam_user" "count2" {
  count = length(var.user_names)
  name  = var.user_names[count.index]
}
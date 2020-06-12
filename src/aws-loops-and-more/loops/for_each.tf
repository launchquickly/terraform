resource "aws_iam_user" "foreach1" {
  for_each = toset(var.user_names)
  name     = each.value
}

resource "aws_autoscaling_group" "foreach2" {

  min_size = 2
  max_size = 10

  dynamic "tag" {
    for_each = var.custom_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
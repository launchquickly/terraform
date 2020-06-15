resource "aws_autoscaling_group" "conditional_example1" {
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
  
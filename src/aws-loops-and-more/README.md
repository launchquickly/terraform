# AWS - loops & conditionals

## Loops

Different looping constructs available:

- `count` parameter: loop over resources
- `for_each` expressions: loop over resources and inline blocks within a resource
- `for` expressions: loop over lists and maps

### `count` parameter

Defines how many copies of the resource to create. e.g.: 
```
resource "aws_iam_user" "example" {
  count = 3
  name  = "neo"
}
```
will look to create 2 IAM users. In this case this will cause an error as the IAM usernames are not unique, which is not allowed. It is possible make this work by differentiating them using `count.index`, where the names would end up as neo.0, neo.1, neo.2:

```
resource "aws_iam_user" "example" {
  count = 3
  name  = "neo.${count.index}"
}
```

It is possible to refine this and produce more readable names using input variables:
```
variable "user_names" {
  description = "Create IAM users with these names"
  type        = list(string)
  default     = ["neo", "trinity", "morpheus"]
}
```
Then by using `count` , array lookups by index and the `length` function to process this list:
```
resource "aws_iam_user" "example" {
  count = length(var.user_names)
  name  = var.user_names[count.index]
}
```
to create 3 IAM users using the values from the list.  This will also work for strings and maps.

When addressing resources created using `count` you need to include the index. e.g.:
```
  user_name = aws_iam_user.example[1].name
```
And to access a **list** of all values you would need to use a *splat expression* `"*"`:
```
  all_arns = aws_iam_user.example[*].arn
```

There are 2 major limitations to the use of `count`:
1. you can't use `count` within a resource loop over *inline* blocks
2. when you change the output of `count`, by for instance removing a name from the middle of the list, as it uses position within the array to identify resources it will instead of destroying the middle resource, update it and destory the third!! This may well cause unexpected and **undesired** side-effects.

### `for_each` expressions

Allows you to loop over lists, sets, and maps to create either:
a. multiple copies of an entire resource
b. multiple copies of an inline block within a resource

#### a. multiple copies of an entire resource

```
resource "aws_iam_user" "example" {
  for_each = toset(var.user_names)
  name     = each.value
}
```
The for_each collection being iterated over at the resouce level needs to be a set or map. Lists are **not** supported when using on a resource.

In the above example it is worth noting the following:
- `toset` to convert from a list to a set as lists are not supported
- each loop will make each user name available in `each.value` and `each.name` as this is a list
- if this where a map being iterated `each.key` and `each.value` would have different values relating to the map structure
- when using `for_each` on a resource, it becomes a map of resources rather than just once resource
    - this means that each element in the collection is now addressable. e.g. if you remove "trinity" from the middle of `var.user_names` list the resource you have removed will be deleted without side-effects on other items, unlike `count`.

#### b. multiple copies of an inline block within a resource

```
resource "aws_autoscaling_group" "example" {
  ...

  dynamic "tag" {
    for_each = var.custom_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
```
In the above example it is the "tag" inline block that is being manipulated. Other points to note:
- when using `for_each` with a **list**, the `key` will be the index, and the `value` will be the item in the list at that index
- when using `for_each` with a **map**, the `key` and `value` value will be as you expect

### `for` expressions

TODO

## Conditionals


## Gotchas


## References:

- [Terraform tips & tricks: loops, if-statements, and gotchas](https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9)

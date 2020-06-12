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
2. when you change the output of `count`, by for instance removing a name from the middle of the list, as it uses position within the array to identify resources it will instead of destroying the middle resource, update it and destory the third!! This may well cause unexpected and undesired side-effects.

## Conditionals


## Gotchas


## References:

- [Terraform tips & tricks: loops, if-statements, and gotchas](https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9)

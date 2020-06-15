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

Use when looking to generate or transform items in a list or map. 

Uppercasing each item in a list can be achieved by:
```
output "upper_names" {
  value = [for name in var.user_names : upper(name)]
}
```

You can also filter items by specifying a condition:
```
output "short_upper_names" {
  value = [for name in var.user_names : upper(name) if length(name) < 5]
}
```

Maps work in a similar way.

And can generate a list result (**NOTE:** [] used):
```
output "bios" {
  value = [for name, role in var.hero_thousand_faces : "${name} is the ${role}"]
}

```

Or output a map result (**NOTE:** {} used):

```
output "upper_roles" {
  value = { for name, role in var.hero_thousand_faces : upper(name) => upper(role) }
}
```

## Conditionals

### `count` parameter

Allows basic conditional logic when constructing resources.

If-statements can be constructed by using `count` in conjunction with a `bool` variable and Terraform's support for *ternary syntax*:
`<CONDITION> ? <TRUE_VAL> : <FALSE_VAL>`
You can then use the `bool` variable to false to set `count` to 0 (not created at all), or true to get 1 or more resources created:
```
  resource "aws_autoscaling_schedule" "scale_out_business_hours" {
    count = var.enable_autoscaling ? 1 : 0
    ...
```

If-Else-statements can be constructed in a similar way using `count` as a conditional parameter on 2 resources but reversing the values that will flip which is created dependent on the true (if) or false (else) value of the variable.

e.g.

```
  resource "aws_iam_user_policy_attachment" "user_cloudwatch_full" {
    count = var.give_full_access ? 1 : 0
    ...

  resource "aws_iam_user_policy_attachment" "user_cloudwatch_readonly" {
    count = var.give_full_access ? 0 : 1
    ... 
```

Whilst simplistic this does allow complexity to be hiddent from users through the use of `bool` variables, in particular, when constructing re-usable modules.


### `for_each` and `for` expressions



## Gotchas


## References:

- [Terraform tips & tricks: loops, if-statements, and gotchas](https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9)

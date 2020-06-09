# Common [Commands](https://www.terraform.io/docs/commands/index.html)

[Initialise](https://www.terraform.io/docs/commands/init.html), or bring up to date, a working directory:
```
terraform init
```


Apply standard [formatting](https://www.terraform.io/docs/commands/fmt.html):
```
terraform fmt
```


Check [validation](https://www.terraform.io/docs/commands/validate.html) and report errors with modules, attribute names, and value types:
```
terraform validate
```


[Display](https://www.terraform.io/docs/commands/plan.html) what would be changed if executed:
```
terraform plan
``` 


[Apply](https://www.terraform.io/docs/commands/apply.html) changes:
```
terraform apply
```
For Terraform >= 0.12 this will also display execution plan. **Earlier versions** (< 0.12) willl require 'terraform plan' to be run explicitly to see the execution plan.


Inspect current state being managed:
```
terraform show
```


Display a specific output value, in this case "ip":
```
terraform output ip
```


[Refresh](https://www.terraform.io/docs/commands/refresh.html) state by comparing it against cloud infrastructure:
```
terraform refresh
```


[Destroy](https://www.terraform.io/docs/commands/destroy.html) resources:
```
terraform destroy
```
It is possible to preview behaviour using: 
```
terraform plan -destroy
```


Mark resource as [tainted](https://www.terraform.io/docs/commands/taint.html):
```
terraform taint resource.id
```
where resource.id refers to the resource block name and resource Id. e.g. aws_instance.example


Modify current [state](https://www.terraform.io/docs/commands/state/index.html) (advanced use only):
```
terraform state <subcommand>
```

# Concepts

## [Providers](https://www.terraform.io/docs/configuration/providers.html)
A plugin that Terraform uses to translate the API interactions with a service, such as AWS or DataDog. 

Providers define the resource types available for it and the arguments each resource type accepts. Providers require configuration, which will be specific to each provider type.

When a new provider is configured is must be initialised before it is used to download and install the provider plugin. This can be done using the command:
```
terraform init
```

## [Resources](https://www.terraform.io/docs/configuration/resources.html)
Defines a piece of infrastructure, whether physical, such as an EC2 instance, or logical, such as a Heroku app.

## Provisioner
Peforms initial setup or configuration on your instances using shell scripts or configuration manangement tools.

## Tainted
Terraform will error and mark a resource as **tainted** if it is successfully created but fails during provisioning. Subsequent execution plans will remove tainted resources and create new resources to replace them.

It is possible to mark a resource as tainted which will destroy and recreate it on the next execution.

Provisioners can also be defined to run only during a destroy operation to peform system cleanup, data extraction, etc.

## Input variables
- Defined in any *.tf file with an optional default value.
- Referenced via prefix var. e.g. var.region
- Assigned either via command-line, from a file, environment varialbes or UI input. 
- Default file location is terraform.tfvars but others can be used. 
- -var-file= argyment can be used to specify file name
- Lists and Maps data types supported

## Output variables
Define variables that are output when apply is called. This allows specific values of interest to be displayed from the thousands available.

## Remote State Storage
Rather than store state locally it is considered best practice to store state using a feature known as remote backends. This allows collaboration across team members too.

# Commands

Apply standard formatting:
```
terraform fmt
```

Check validation and report errors with modules, attribute names, and value types:
```
terraform validate
```

Display what would be changed if executed:
```
terraform plan
``` 

Apply changes:
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

Refresh state by comparing it against cloud infrastructure:
```
terraform refresh
```

Destroy resources:
```
terraform destroy"
```

Mark resource as tainted:
```
terraform taint resource.id
```
where resource.id refers to the resource block name and resource Id. e.g. aws_instance.example

Modify current state (advanced use only):
```
terraform state
```
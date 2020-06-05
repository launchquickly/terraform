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

## [Provisioners](https://www.terraform.io/docs/provisioners/)
Peforms initial setup or configuration on your instances using shell scripts or configuration manangement tools.

Are a **last resort** and other mechanisms to consider before contemplating using as part of Terraform include:
- Build images which have been configured already using a tool such as [Packer](https://www.packer.io/).
- Instead of having a provisioner pass data in determine whether it is available via [cloud-init(]https://cloudinit.readthedocs.io/en/latest/)
- Use local-exec to run CLI for target system where that isn't yet supported in its Terraform provider. Consider opening an issue to have this added too.

*provisioner* blocks can be declared within *resource* blocks. Usually, but not always (e.g. local-exec), they must include a *connection* block to allow Terraform to communicate with the server.

Provisioners **only** run during creation unless configured as a destroy-time provisioner when it will run before the resource is destroyed.

If more than one provisioner is specified within a resource they will run in the order they are declared.

Failure behaviour can be specified as either *fail*, the default, or *continue*, which will ignore the error.

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

## [Remote State Storage](https://www.terraform.io/docs/state/remote.html)
Rather than store state locally it is considered best practice to store state using a feature known as remote backends. This allows collaboration across team members too.

## [Workspaces](https://www.terraform.io/docs/state/workspaces.html)
Persistent data stored in a [backend ](https://www.terraform.io/docs/backends/index.html) belongs to a workspace. There is always a "default" workspace. In addition some backends support *multiple* named backends, allowing multiple states to be associated with a single configuration.

Running a terraform plan whilst in one workspace will not affect the other. It is possible to determine the current workspace using:
```
${terraform.workspace}
```
this can be used to change behavior based on workspace.

Workspaces are convenient for switching between multiple instances of a single configuration with a single backend to test a set of changes before modifying the main production infrastructure. It is common that a workspace might be used to test a feature branch before merging to master or trunk. Workspaces and branches used in this way can be destroyed after the merge.

Workspaces are not suitable for serving different development stages or teams as these often need to have different credentials or backends.

Similarly workspaces should not be used for system decomposition as this should be done using architectural boundaries with each subsytem in the architecture having its own configuration and backend. 

## Modules

Modules can help address organisation, encapsulation, re-use and consistency and best practice issues as terraform configurations become more complex.

They allow:
- organising configuration into logical components
- encapsulating distinct areas together reducing the chance and impact of errors
- reuse of configurations to save time and effort
- help enforce consistency and best practices

Modules are directories containing one or more Terraform configuration files and are called using module blocks and can be loaded from the local filesystem, or a remote resource.

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


Refresh state by comparing it against cloud infrastructure:
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
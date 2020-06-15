# Concepts

## [Providers](https://www.terraform.io/docs/configuration/providers.html)

A plugin that Terraform uses to translate the API interactions with a service, such as AWS or DataDog. 

Providers define the resource types available for it and the arguments each resource type accepts. Providers require configuration, which will be specific to each provider type.

When a new provider is configured is must be initialised before it is used to download and install the provider plugin. This can be done using the command:
```
terraform init
```
`terraform init` cannot automatically download Community providers and these need to be manually installed into the user plugins directory located at ~/.terraform.d/plugins.


## [Resources](https://www.terraform.io/docs/configuration/resources.html)

Defines a piece of infrastructure, whether physical, such as an EC2 instance, or logical, such as a Heroku app.
```
resource "aws_instance" "web" {
    ami           = "ami-a1b2c3d4"
    instance_type = "t2.micro"
}
```
The above example declares a resource type (`"aws_instance"`) with a given name (`"web"`). The combination of both must be unique within a module. Resource types belong to a specific provider. [Terraforms provder documentation](https://www.terraform.io/docs/providers/index.html) details providers and which resources are available along with which arguments to use to configure them.

Most resource dependencies, if they exist, are handled automatically. However, some dependencies cannot be recongnised implicitly in configuration and if needed the `depends_on` can be used to declare explicit dependencies.

Other meta-arguments available include:
- [depends_on](https://www.terraform.io/docs/configuration/resources.html#depends_on-explicit-resource-dependencies), for specifying hidden dependencies
- [count](https://www.terraform.io/docs/configuration/resources.html#count-multiple-resource-instances-by-count), for creating multiple resource instances
- [for_each](https://www.terraform.io/docs/configuration/resources.html#for_each-multiple-resource-instances-defined-by-a-map-or-set-of-strings), to create multiple instances according to a map, or set of strings
- [provider](https://www.terraform.io/docs/configuration/resources.html#provider-selecting-a-non-default-provider-configuration), for selecting a non-default provider configuration
- [lifecycle](https://www.terraform.io/docs/configuration/resources.html#lifecycle-lifecycle-customizations), for lifecycle customisations
- [provisioner and connection](https://www.terraform.io/docs/configuration/resources.html#provisioner-and-connection-resource-provisioners), for taking extra actions after resource creation

Local-only resource types operate only within Terraform itself, calculating some results and saving those results in state for future use. They are typcially used for generating random ids, helping to self-sign TLS certificates or similar.

## [Provisioners](https://www.terraform.io/docs/provisioners/)

Peforms initial setup or configuration on your instances using shell scripts or configuration manangement tools.

Are a **last resort** and other mechanisms to consider before contemplating using as part of Terraform include:
- Build images which have been configured already using a tool such as [Packer](https://www.packer.io/).
- Instead of having a provisioner pass data in determine whether it is available via [cloud-init](https://cloudinit.readthedocs.io/en/latest/)
- Use `local-exec` to run CLI for target system where that isn't yet supported in its Terraform provider. Consider opening an issue to have this added too.

`provisioner` blocks can be declared within `resource` blocks. Usually, but not always (e.g. `local-exec`), they must include a `connection` block to allow Terraform to communicate with the server.

Provisioners **only** run during creation unless configured as a destroy-time provisioner when it will run before the resource is destroyed.

If more than one provisioner is specified within a resource they will run in the order they are declared.

Failure behaviour can be specified as either `fail`, the default, or `continue`, which will ignore the error.

## [Data Sources](https://www.terraform.io/docs/configuration/data-sources.html)

Let Terraform fetch and compute data for use elsewhere, defined outside of Terraform, or defined by another separate Terraform configuration.
```
data "aws_ami" "example" {
    filter {
        name   = "state"
        values = ["available"]
    }

    filter {
        name   = "tag:Component"
        values = ["web"]
    }

    most_recent = true

    owners = ["self]
    tags = {
        Name   = "app-server"
        Tested = "true"
    }
}
```
Data sources are associated with a single data source, which determines the kind of object it reads and what query constraints are available. They belong to specific providers.

If query constraint arguments are constant values or already known they are read and its state updated during the "refresh" phase. Those that cannot be known until after the configuration is applied are deferred until the apply phase.

Data resources have the same dependency resolution behaviour as managed resources, including `depends_on` which will defer the read until the apply phase.

`count`, `for_each` and `provider*`meta-arguments are available too but `lifecycle` is not currently.

## Tainted
Terraform will error and mark a resource as `tainted` if it is successfully created but fails during provisioning. Subsequent execution plans will remove tainted resources and create new resources to replace them.

It is possible to mark a resource as tainted which will destroy and recreate it on the next execution.

Provisioners can also be defined to run only during a destroy operation to peform system cleanup, data extraction, etc.

## Input variables

- Defined in any *.tf file with an optional default value.
- Referenced via prefix var. e.g. var.region
- Assigned either via command-line, from a file, environment varialbes or UI input. 
- Default file location is terraform.tfvars but others can be used. 
- `-var-file=` argument can be used to specify file name
- Lists and Maps data types supported

## Output variables

Define variables that are output when apply is called. This allows specific values of interest to be displayed from the thousands available.

## [Refresh](https://www.terraform.io/docs/commands/refresh.html)

Refreshing state can reconcile state Terraform knows about via state file with real-world infrastructure. It will not modify infrastructure but modifies the state file and **could** cause changes during the next plan or apply.

## [Debugging Terraform](https://www.terraform.io/docs/internals/debugging.html)

Terraform has detailed logs which can be enabled to log to *stderr* by setting the `TF_LOG` environment variable. It can be set to any value which will enable logging at the TRACE level but alternatively specific log levels can be set by using one of the follow values: `TRACE`, `DEBUG`, `INFO`, `WARN` or `ERROR`.

`TF_LOG_PATH` if set can be used to append to a specific file when logging is enabled.

If Terraform ever crashes it saves a log file with debug logs from the session to *crash.log*.
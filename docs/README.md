# Concepts

## [Providers](https://www.terraform.io/docs/configuration/providers.html)

A plugin that Terraform uses to translate the API interactions with a service, such as AWS or DataDog. 

Providers define the resource types available for it and the arguments each resource type accepts. Providers require configuration, which will be specific to each provider type.

When a new provider is configured is must be initialised before it is used to download and install the provider plugin. This can be done using the command:
```
terraform init
```
*terraform init* cannot automatically download Community providers and these need to be manually installed into the user plugins directory located at ~/.terraform.d/plugins.


## [Resources](https://www.terraform.io/docs/configuration/resources.html)

Defines a piece of infrastructure, whether physical, such as an EC2 instance, or logical, such as a Heroku app.
```
resource "aws_instance" "web" {
    ami           = "ami-a1b2c3d4"
    instance_type = "t2.micro"
}
```
The above example declares a resource type ("aws_instance") with a given name ("web"). The combination of both must be unique within a module. Resource types belong to a specific provider. [Terraforms provder documentation](https://www.terraform.io/docs/providers/index.html) details providers and which resources are available along with which arguments to use to configure them.

Most resource dependencies, if they exist, are handled automatically. However, some dependencies cannot be recongnised implicitly in configuration and if needed the *depends_on* can be used to declare explicit dependencies.

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
- Use local-exec to run CLI for target system where that isn't yet supported in its Terraform provider. Consider opening an issue to have this added too.

*provisioner* blocks can be declared within *resource* blocks. Usually, but not always (e.g. local-exec), they must include a *connection* block to allow Terraform to communicate with the server.

Provisioners **only** run during creation unless configured as a destroy-time provisioner when it will run before the resource is destroyed.

If more than one provisioner is specified within a resource they will run in the order they are declared.

Failure behaviour can be specified as either *fail*, the default, or *continue*, which will ignore the error.

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

Data resources have the same dependency resolution behaviour as managed resources, including *depends_on" which will defer the read until the apply phase.

*count*, *for_each* and *provider* meta-arguments are available too but *lifecycle* is not currently.

## Tainted
The exception is 
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

## [State Locking](https://www.terraform.io/docs/state/locking.html)

If supported by your backend, locking state will occur for all operations that could involve writing state. If state locking fails, Terraform will not continue. You can disable state locking with the *-lock* flag but it is **not** recommended.

You can [force-unlock](https://www.terraform.io/docs/commands/force-unlock.html) to manually unlock state if unlocking failed. **Be extermely careful with this command.**

## [Sensitive data in state](https://www.terraform.io/docs/state/sensitive-data.html)

Terraform can end-up storing sensitive data depending on the resources being managed. Local state will store state in plain-text JSON files. Remote state is only ever held in memory by Terraform but how it is stored will depend on the specifics of the back-end.

Treat Terraform state as sensitive data in these circumstances. Storing state remotely can provide better security as some backends can be configured to encrypt state data at rest. Some possible options include Terraform Cloud and S3 backend both of which can support encryption at rest and TLS in transit.

## [Backends](https://www.terraform.io/docs/backends/index.html)

Backends determine how state is loaded and how operations such as *apply* are executed. By default the backend is a "local". There are number of [backend types](https://www.terraform.io/docs/backends/types/index.html) available. These are defined as either:
- **Standard**: state management, functionality covered in [State Storage & Locking](https://www.terraform.io/docs/backends/state.html)
- **Enhanced**: Everything in standard plus [remote operations](https://www.terraform.io/docs/backends/operations.html)

Rather than store state locally it is considered best practice to store state using a feature known as [remote backends]https://www.terraform.io/docs/state/remote.html). This allows collaboration across team members too and keeps sensitive information off of disk. 

Backends are configured in the *terraform* section, configuration will be specific to the backend type:
```
terraform {
    backend "consul" {
        address = "demo.consul.io"
        scheme  = "https"
        path    = "example_app/terraform_state"
    }
}
```

When configuring a backend for the first time you will be given the option to migrate state to the new backend.

Partial configuration of backends allows omitting certain arguments to avoid storing secrets, such as access keys, wihtin the main configuration. This means that the remaining configuration arguments need to be provided by one of:
- Interactively
- A configuration file specified via the *init* command using the *-backend-config=PATH* option.
- Command-line key/value pairs in the *init* command using the *-backend-config="KEY=VALUE"* option.

When using a non-local backend will not persist the state anywhere on disk. Except to prevent data loss in the case of a non-recoverable error where writing the state to the backend failed. If this happens the user must manually push the state to the remote backend once the error is resolved.

[Remote operations](https://www.terraform.io/docs/backends/operations.html) are currently only supported by the *[remote](https://www.terraform.io/docs/backends/types/remote.html)* backend with [Terraform Cloud](https://www.terraform.io/docs/cloud/index.html) is the only remote execution environment that supports it.

## [Refresh](https://www.terraform.io/docs/commands/refresh.html)

Refreshing state can reconcile state Terraform knows about via state file with real-world infrastructure. It will not modify infrastructure but modifies the state file and **could** cause changes during the next plan or apply.

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

Modules are directories containing one or more Terraform configuration files and are called using module blocks and can be loaded from the local filesystem, or a remote resource. After adding, removing or modifying *module* blocks you must re-run *terrform init* to allow terraform to adjust the installed modules. To upgrade modules you need to use the *- upgrade* option.


[Input variables](https://www.terraform.io/docs/configuration/variables.html) serve as parameters for modules and allowing modules to be used in different configurations. They are declared in a *variable* block with a name that must be unique within the module and can be any identifier, **other** than *source, version, providers, count, for_each, lifecycle, depends_on and locals*, which are reserved meta-arguments. Optionally a *type* and *default* arguments can be specified along with a *description* to document it.

[Terraform Registry](https://registry.terraform.io/) hosts and [makes searchable and retrievable](https://www.terraform.io/docs/registry/modules/use.html) a number of public modules. When referencing a registry module the syntax is: <NAMESPACE>/<NAME>/<PROVIDER>, e.g. hashicorp/consul/aws and can be referenced in a configuration by:
```
module "consul" {
    source = "hashicorp/consol/aws"
    version = "0.1.0"
}
```

[Semantic versioning](https://semver.org/) is the recommended and usual way to version modules.

It is [recommended](https://www.terraform.io/docs/configuration/modules.html#module-versions) that external modules be **explicitly** constrained to avoid unwanted changes

### Private Module Registry

Private module registries can be used to create and confidentially share infrastructure modules within an organisation. Terraform Cloud provides this as a managed capability but there are other providers. A private module registry allows the import and management of a Terraform module from github or other version control systems.

Private registry module source need to also include the hostname: <HOSTNAME>/<NAMESPACE>/<NAME>/<PROVIDER>
```
module "consul" {
    source = "app.terraform.io/launchquickly/vpc/aws"
    version = "0.1.0"
}
```

### Code organisation

Monolithic configuration consists of a single main configuration file in a single directory, with a single state file. It may be possible to manage small configurations this way but it is not recommended.

Organising configuration into separate environment files, for instance dev.tf and prod.tf, but in the same directory is a bad idea as Terraform loads all configuration files within the directory. This will lead to changes meant for dev affecting prod because of the difficulty of having dependencies within the config, either explicit and obvious or hidden and easy to miss.

State separation adds complexity but is a more mature usage of Terraform. There are 2 recognised methods to separate state between environments:
- directories
- workspaces

**Directory** separated environments are pretty much what you would imagnine. They shrink the blast-radius of your Terraform runs having separate state in each envs directory. This does mean that there is a reliance on a level of duplication in code across environment directories. This can however be useful where environments need to differ but also opens up the risk of drift between environments. Using modules to encapsulate changes should be considered to combat drift.

**Workspace** separated environments use the same Terraform code but different state files, which is useful if you want the environments to stay as similar to each other as possible. For each environment you will need:
- a named workspace, e.g. dev, prod, etc
- a named varibales.tf file, e.g. dev.tf, prod.tf etc
You can then use the commands similar to the below to work on and apply changes to specific enviroments:
```
#terraform workspace new dev
terraform workspace select dev
terraform apply -var-file=dev.tfvars
```
When you use the default workspace with the local backend, your terraform.tfstate file is stored in the root directory. Adding additional workspaces stores and manages state files in the directory terraofrm.tfstate.d using subdirectories named after the workspace/env.

There are pluses and minuses to the use of directory or workspace separation. Workspaces are ideal for creating exact replica environments and directory separation is more useful for isolating and making changes such as promoting change through a delivery pipeline.

### Stack configurations

Typical Stack structures within an organisation might decompose into something similar to the below, possibly managed by different teams:

| Level       | Group      | Component Configuration                          | 
| ------------|:----------:|:------------------------------------------------:|
| Network     | Network    | VPC/Subnets                                      |
| Security    | Security   | Security Groups/IAM                              |
| Data        | DBA        | RDS                                              |
| Application | Developers | App Load Balancers/Auto Scaling Groups/Nomad/K8s |

Decomposition has several benefits, both at the code but also reducing the blast radius of changes, allows different rates of change as well as emphasisiing code re-use through the use of modules. The use of separate workspaces also allows that permissions and responsibilities can be managed across teams.

Splitting and structuring at architectural and/or team boundaries also ensures clear and known responsibilities as well as allowing changes to occur in parallel.

#TODO investigate how IaC Pipelines and/or Terragrunt may be a 3rd option.

## [Terraform Cloud](https://www.terraform.io/docs/cloud/index.html)

Is an application that helps teams use Terraform together providing consistent reliable environments, shared state, secret data controls, access controls for approving changes to infrastructure, private module registry, and policy controls.

Structure of each [workspaces](https://www.terraform.io/docs/cloud/workspaces/index.html) in Terraform Cloud
- associated with configuration
- provide variables for configuration files
- Runs are scheduled/queued:
-- plan stage
-- Sentinel stage
-- apply stage
- state file
- permissions set on workspace

Typical Stack structures can leaverage workspaces to gain and operationalise the benefits outlined above in [Stack configurations](#stack-configurations)

The use of separate workspaces also allows that permissions and responsibilities can be managed across teams.

## [Debugging Terraform](https://www.terraform.io/docs/internals/debugging.html)

Terraform has detailed logs which can be enabled to log to *stderr* by setting the *TF_LOG* environment variable. It can be set to any value which will enable logging at the TRACE level but alternatively specific log levels can be set by using one of the follow values: *TRACE, DEBUG, INFO, WARN* or *ERROR*.

*TF_LOG_PATH* if set can be used to append to a specific file when logging is enabled.

If Terraform ever crashes it saves a log file with debug logs from the session to *crash.log*.

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

# References:

- [Terraform Documentation](https://project-awesome.org/shuaibiyy/awesome-terraform)
- [Awesome Terraform](https://project-awesome.org/shuaibiyy/awesome-terraform)

# TODO

- Learn about [Terragrunt](https://project-awesome.org/shuaibiyy/awesome-terraform) to see if it enables [IaC Pipelines](https://medium.com/@kief/https-medium-com-kief-using-pipelines-to-manage-environments-with-infrastructure-as-code-b37285a1cbf5).
- Investigate [Open Policy Agent](https://project-awesome.org/shuaibiyy/awesome-terraform) | [OPA is to Policy Automation as Terraform is to IaC](hhttps://www.scalr.com/blog/opa-is-to-policy-automation-as-terraform-is-to-iac/)
- Read [The Right Way to Store Secrets using Parameter Store](https://aws.amazon.com/blogs/mt/the-right-way-to-store-secrets-using-parameter-store/) and compare with use of [Vault](https://www.terraform.io/docs/providers/vault/index.html) for secrets and other suggestions at [How can I manage secrets in .tf and .tfstate?](https://devops.stackexchange.com/questions/79/how-can-i-manage-secrets-in-tf-and-tfstate)
- Look into Segment.io [Stack AWS](https://github.com/segmentio/stack) AWS Terraform configuration. 
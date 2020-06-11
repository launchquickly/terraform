# AWS - Remote state management 

This example will illustrate how Terraform manages state, including:
- How to bootstrap a remote backend
- Ways of isolating state files
- Sharing of state data and how that can happen

By default Terraform stores state locally. This has a number of obvious practical problems, particularly for security and around collaboration across a team or organisation such as:
- shared storage of state files
- locking of state files
- isolating state files and the corresponding to environments and/or infrastructure they manage
- management of secrets

Remote backends solve the issues around loading and storing state  as well as the management of secrets. Good practice helps with isolation of state.

## Bootstrapping terraform remote backend

The combination of S3 and DynamoDB provides a robust and reliable remote backend for Terraform when using AWS. Benefits include:
- S3 and DynamodDB are managed services
- High durability and availability of these services
- Encyption supported at rest (AES-256) and in transit (TLS)
- Locking supported via DynamoDB
- Supports versioning
- Low cost

Before you can use S3 and DynamoDB as a remote backend they require to be created. The [main.tf](./bootstrap/main.tf) sets these both up. Key settings to note are:
- S3 configuration
    - versioning is enabled
    - encryption is enabled
- DynamoDB
    - the primary key configured **must** be called `LockID`, including capitalization

Running `terraform init` and then `terraform apply` for [main.tf](./bootstrap/main.tf) locally will deploy and configure both these services. Obviously region, etc configruation should be reviewed first.

Once that is done update [bootstrap/main.tf](./bootstrap/main.tf) with the changes in [remote/main.tf](./remote/main.tf) and add [outputs.tf](./remote/outputs.tf) this configures an `"s3"` `backend` wihin the `terraform` block. Key settings include:
- bucket and dynamodb table exactly match that set-up previously
- `encrypt` is set to true to enable a second layer of encryption when stored in S3, in addition to the bucket encryption
- `key` file path is namespaced to indicate the state being stored. e.g. `gloabal` and `s3` path to `terraform.tfstate`

Running `terraform init` will detect that there is a state file locally and prompt to allow it to be copied to the S3 backend. Now if you run `terraform apply` again a lock will be acquired and the state will be versioned as well as the state being pushed and pulled to and from S3.

## Isolating state files

Defining all of your infrastructure in a single terraform file or single set of files has real risks. Isolating changes across environments and infrastructure areas reduces risk considerabley. There are 2 wasy to do this using terraform:
- **Isolation via workspaces** - useful for quick, isolated tests on the same configuration.
- **Isolation via file layout** - useful for production use-cases where you need strong separation between environments.

### Isolation via workspaces

Terraform workspaces allow you to store Terraform state in multiple separate, named workspaces. Terraform starts with a single workspace called "default".  To create a new and switch to a workspace called "example1 "you use the following:
```
terraform workspace new example1
```
Running `terraform apply` now will create any infrastructure or resources within the "example1" workspace.

You can list workspaces by:
```
terraform workspace list
```

Switch between them by:
```
terraform workspace select default
```

The only realy difference with the [main.tf](./workspaces/main.tf) in the workspaces folder is the key of the backend is namespaced to indicate it is being used for a workspace example. Each workspace state file (other than default) will be stored in the subdirectory of the *"env:"* directory with the same name as the workspace.

Workspaces are great for spinning up and tearing down copies of different versions of code but do have serious drawbacks:
- state file for all workspaces uses the same backend and therefore the same authentication and access controls so has weak security across workspaces
- isolation is not at the code level and not visible meaning you don't have a good picture of infrasturcture 
- they can be fairly error prone as they rely on not peforming an action on the wrong workspace

### Isolation via file layout

Splitting terraform configuration out into directory and file structures enables:
- separation of environments into named folders such as `stage` and `prod`
- separation of backends at the environment and other levels which then allows more control over access and authentication controls

You can further take the isolation concept to the component level which help isolate differnt types of changes from each other and further provide more granular levels to different teams and users.

The [filelayout](./filelayout/) directory structure outlines an example of how you might separate and isolate environments into:

- [stage](./filelayout/stage/) - pre-production workloads
- [prod](./filelayout/prod/) - production workloads
- [mgmt](./filelayout/mgmt/) - environment for DevOps tooling
- [global](./filelayout/global/) - area for resources used across all environments e.g. S3 and IAM

Then within each environment there are separate folders at the component level, such as:

- [vpc](./filelayout/stage/vpc/) - network topology
- [services](./filelayout/stage/services/) - applications, etc
- [data-storage](./filelayout/stage/data-storage/) - data stores of different kinds

Which can then have standard file naming conventions to make code easier to browse and locate. 

- [variables.tf](./filelayout/stage/data-storage/mysql/variables.tf) Input variables
- [outputs.tf](./filelayout/stage/data-storage/mysql/outputs.tf) Output variables
- [main.tf](./filelayout/stage/data-storage/mysql/main.tf) Resource and other configuration definitions

This provides a browsable model of environments and related components which reflect their current state and configuration details. It also provides a much higher level of isolation which means if something does go wrong then it affects a much smaller blast radius.

It does however mean you can't create everything in a single command and now resource dependencies are not taken care of by terraform as the state isn't available. Terraform does offer a solution for this, the `terraform_remote_state` data source.

## terraform_remote_state_data source

The `terraform_remote_state` data source can be used to fetch state file stored by another set of templates.

In [stage/data-storage/mysql/main.tf](./filelayout/stage/data-storage/mysql/main.tf) there is a `aws_db_instance` declared for a MySQL database. The backend stores the state of this resource and others withing S3 at: `stage/data-stores/mysql/terraform.tfstate`. The [stage/services/webserver-cluster/main.tf](./filelayout/stage/services/webserver-cluster/main.tf) can access declared **output variables** (read-only) by declaring a data source:
```
data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = "lq-terraform-up-and-running-state"
    key    = "stage/data-storage/terraform.tfstate"
    region = "us-east-2"
  }
}
```
This allows various isolated components and indeed environments to publish information about their state that can then be used by other components/environments. This allows data **contracts** to be created across environments and enforce dependencies across isolated layers. 

## References:
- [How to manage Terraform state](https://blog.gruntwork.io/how-to-manage-terraform-state-28f5697e68fa)
- [Terraform, VPC, and why you want a tfstate file per env](https://charity.wtf/2016/03/30/terraform-vpc-and-why-you-want-a-tfstate-file-per-env/)

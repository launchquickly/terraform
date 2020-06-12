# AWS - Modules

Modules in Terraform are a key way to remove duplication of code and enable the creation of reusable infrastructure definitions. Combining modules with a file layout of Terraform projects can minimise duplication and provide consistency between environments.

## Basics

All sets of Terraform configuration files are modules as even self-contained terraform code is said to reside in the *root module* whether it calls other modules or not.

They syntax for using a module is:
```
module "<NAME>" {
    source = "<SOURCE>"

    [CONFIG ...]
}
```
You need to run `terraform init` prior to using a module, or if you modify the `source` parameter, before running `plan` or `apply`.

[modules/services/webserver-cluster](./modules/services/webserver-cluster/) contains a reusable module for creating a webserver cluster. Changes from the original standalone code include:
- `provider` definition has been removed as these will be configured by the calling code
- *input parameters* are defined using [input variables](./modules/services/webserver-cluster/variables.tf) for elements of the module that should be dynamic, these are accessed in the module code using the `var.<VARIABLE_NAME>` instead of hard-coded names.
    - such as naming elements to make resources unique and identifiable, e.g. `"name = ${var.cluster_name}-elb"`
    - configuration options that will differ, such as instance size or number of instances, e.g. `instance_type = var.instance_type`
- *output parameters* are defined using [output variables](./modules/services/webserver-cluster/outputs.tf) and allow values available from the module to be made available to calling configuration code.
    - these output variables are then accessible using `module.<MODULE_NAME>.<OUTPUT_NAME>`
    - often you may want to expose some of these module output values by creating a chained output variable definition within the calling code.

[stage/services/webserver-cluster/main.tf](./live/stage/services/webserver-cluster/main.tf) illustrates how this module is called and configured for the staging environment.

[prod/services/webserver-cluster/main.tf](./live/prod/services/webserver-cluster/main.tf) illustrates how this same module is called and configured for the production environment. It also illustrates how additional configuration can be added alongside module calls and makes use of module output variables in the case of setting `autoscaling_group_name = module.webserver_cluster.asg_name`.

The use of input and output parameters/variables allows contracts to be set-up between calling code.

## Versioning

Versioned modules are necessary to provide isolation between changes withinn them. Using local modules across environments would mean that any changes made for staging would also affect production on the next deployment.

Terraform supports [module sources](https://www.terraform.io/docs/modules/sources.html). 

An easy way to create a versioned module is to put the code in a separate Git repository and set the `source` parameter to that respoistory's URL. This involves:
- a separte modules repository or even a separate repository per module
- tag versions of modules using [semantic versioning](https://semver.org/) conventions
- reference these versions within the `source` paramter using the `ref` parameter to sepcificy the version, similar to: 
```
  ...
  source = "github.com/foo/modules//webserver-cluster?ref=v0.0.1'
  ...
```

For Git repositories within private Git repositories using SSH auth and a SSH form in the `source` URL should be used:
```
  ...
  source = "git::git@github.com:launchquickly/repo-name.git//modules/webserver-cluster?ref=v0.0.1'
  ...
```

This now enables using different versions of modules in different environments, providing isolation of changes and allowing changes to go through a promotion process that can test and prove these changes.

## References:

- [How to create reusable infrastructure with Terraform modules](https://blog.gruntwork.io/how-to-create-reusable-infrastructure-with-terraform-modules-25526d65f73d)


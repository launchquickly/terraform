# Development and Delivery pipeline practices

1. [Use version control](#1.-use-version-control)
2. [Run the code locally](#2.-run-code-locally)
3. [Make code changes](#3.-make-code-changes)
4. [Submit changes for review](#4.-submit-changs-for-review)
5. [Run automated tests](#5.-run-automated-tests)
6. [Merge and release](#6.-merge-and-release)
7. [Deploy](#7.-deploy)

This section uses the IaC workflow practices outlined in [How to use Terraform as a team](https://blog.gruntwork.io/how-to-use-terraform-as-a-team-251bc1104973) as a basis for documenting a baseline for IaC code development and delivery pipeline practices relating to Terraform. As more experience or additional knowledge is gained these will be amended to reflect that.

## 1. Use version control

Infrastructure code should be version controlled. For infrastructure code there are a few additional requirements to note:

### 1.1. Live and modules repositories

There will typically be a minimum of 2 separate version control repositories:
- `modules` - a repository (or optionally repositories) of reusable Terraform modules.
- `live` - live environments (e.g. dev, state, prod) you deploy using versioned Terraform modules.

[`modules`](./mechanics-organisation.md#modules) - should follow the practices outlined in the [examples](../src/aws-modules/README.md).

`live` should follow the pattern outlined in the [file layout](../src/aws-remote-backend/README.md#isolation-via-file-layout) method of isolation, as well as looking to further structured decomposition as outlined in [Stack configurations](./mechanics-organisation.md#stack-configurations). 

For reference it is worth browsing this example [file layout](../src/aws-remote-backend/filelayout) directory structure.

### 1.2. The Golden Rule of Terraform

The master branch of the live repository shoudl be a 1:1 representation of what's actually deployed in production.

This means:
- **never** make *out-of-band-changes* - all changes are made via Terraform - not manually, via UI or other API
- **1:1 representation** - don't use workspaces and don't have out-of-band changes
- **master branch** - you should only have to look at a single branch to understand what is deployed in production.

### 1.3. The trouble with branches

Having a single state file will not save you from multiple branches as there is now 2 representations of the same configuration. Do not have **any** branches representing the same environment. It doesn't work.

## 2. Run the code locally

Use *sandbox environments*, such as an AWS account dedicated for developers, or even one AWS account for each developer to make changes and create automated tests using [Terratest](https://blog.gruntwork.io/open-sourcing-terratest-a-swiss-army-knife-for-testing-infrastructure-code-5d883336fcd5) or similar.

With a sanbox environment you can *consider* using a branch for your code as long as it is 1:1 with the sandbox environment.

## 3. Make code changes

Make and iterate on your changes, running `terraform apply` to deploy the changes. 

If this is a `module` change it should be done on trunk as it will be isolated by the use of versions.

If it is to the `live` repository a branch may need to be considered to isolate the change whilst working within the sandboxed environment. 

Consider what test strategies you can use to shorten the test cycle: [Terratest's test stages](https://github.com/gruntwork-io/terratest#iterating-locally-using-test-stages)

Make regular commits, for successful changes, as you go.

## 4. Submit changes for review

Code should be reviewed via pull request or similar. This will likely have the following checks:
- does the code work as intended
- is the testing sufficient and can be run error free
- does the code meet coding guidelines
-- style guidelines
-- patterns and conventions met
- is the change and everything else sufficiently documented
-- README
-- Design docs and decisions
-- Examples if introducing something new

## 5. Run automated tests

- Run on CI server
-- Run unit, integration, e2e tests
-- Static analysis
-- Alway run `plan` before `apply` and capture the output for immediate check and later analysis

## 6. Merge and release

Once review and any required changes from this have been made then the module or branch will need promoted:

- For modules, this will be releasing a new (tagged) version and any update to the configuration of `live` and `terrafrom init --upgrade` being run to ensure the new version is used
- For `live`, this will a merge of the branch and a tagging that version of the repository that can be promoted as an immutable artifact
-- Using the file layout pattern of isolation can involve duplication of code so it may be necessary to mirror changes across the *environment* directories, moving an env specific versioned tag as the changes are determined to be successful. **This needs more thought**

## 7. Deploy

Key considerations for deploying Terraform code:

1. Deployment tooling
2. Deployment strategies
3. Deployment server
4. Promote artifacts across environments

### 1. Deployment tooling

Options include:
- Terraform Cloud - managed service backend
- Terragrunt - open source tool
- Scripts - custom bespoke scripts

### 2. Deployment strategies

As Terraform is **declarative** any deployment strategy is limited. 

Points to keep in mind:
- Incremental co-ordinated changes
- Create before destroy, either by configuration or multiple logical incremental releases can reduce risk

Due to these limitations it is critical to taken into account what happens when a deployment goes wrong. Rollback are not automatic and may well not be safe or possible so having a deployment strategy that assumes errors are (relatively) normal and deals with them should be considered. This should include:
- **Retries** - errors may be transient. Re-run `terraform apply`. Terragrunt has automatic retries of known errors as a feature.
- **Terraform state errors** - if because of connectivity or other reasons Terraform cannot comlete writing state to a remote backend the `errored.tfstate` file should be preserved and it should be pushed to the remote backend using `terraform state push` as soon as possible.
- **Errors releasing locks** - if Terraform fails to release a lock the CI server may crash in the middle of a `terraform apply` and the state will be permanently locked. Once the cause is confirmed and you are sure it is safe to do so you can forcibly resolve this using the `terraform force-unlock` command, passing it the ID of the lock from the error message.

### 3. Deployment server

Recommendations:
- Don't expose your CI server on the public internet but use a private subnet, without any public IP, only accessible via VPN
- Lock the CI server down - strong user authentication and authorisation, locked down firewall, fail2ban, enable audit logging etc.
- Consider managing the CI server admin credentials so that permissions expire/need rotated and/or elevated. 

### 4. Promote artifacts across environments

**Always test Terraform changs in staging before prod**

- Promote immutable versioned infrastructure artifacts from environment to environment (Known Good Configuration!)
- Remeber Terraform does not rollback changes in error cases so you have to be able to cater for this and fix it/learn from it if necessary
- **Always* run `terraform plan` and review the output


## References:

- [How to use Terraform as a team](https://blog.gruntwork.io/how-to-use-terraform-as-a-team-251bc1104973)
- [Open sourcing Terratest: a swiss army knife for testing infrastructure code](https://blog.gruntwork.io/open-sourcing-terratest-a-swiss-army-knife-for-testing-infrastructure-code-5d883336fcd5)
- [Terratest](https://terratest.gruntwork.io/)
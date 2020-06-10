# AWS - Simple cluster

This example will illustrate the following:
- Set-up of AWS provider
- Deployment and configuration of cluster of web servers
- Deployment of load balancer

## Set-up of AWS provider

### Create a user with permissions to access AWS

1. Create an AWS user account with programmatic access but **not** able to login to AWS Console
2. Ensure they have an IAM policy assigned to them that allows `AmazonEC2FullAccess` permissions 
3. Download and store safely the access key and secret generated for this user
4. Run the following command and use their values to configure access:
```console
vagrant@tf-server:~$ aws configure
AWS Access Key ID [None]: XXX
AWS Secret Access Key [None]: XXX
Default region name [None]: 
Default output format [None]: 
```
This will create a file `~/.aws/credentials` from which Terraform can retrieve AWS credentials from.

Alternatively you could set environment variables each time you run a session:
```
export AWS_ACCESS_KEY_ID=XXX
export AWS_SECRET_ACCESS_KEY=XXX
```

### Add provider to configuration

A typical provider configuration for AWS is similar to the below:
```
provider "aws" {
    version = "~> 2.65"
    region = var.region
}
```
Defining `region` is optional but it must be provided either from `AWS_DEFAULT_REGION` env variable or via shared credentials configuration.

`version` is also optional but constraining this value is seen as a good practice to avoid upgrades of major version causing breaking changes.

## Deployment and configuration of cluster of web servers

AWS enables the configuration of a cluster of servers. To create this you need to: 

1. Create a [launch configration](https://docs.aws.amazon.com/autoscaling/ec2/userguide/LaunchConfiguration.html), which specifies how to configure each EC2 instance by using the [`aws_launch_configuration`](https://www.terraform.io/docs/providers/aws/r/launch_configuration.html) resource.
1.1. The `lifecycle` setting in this example is set to `create_before_destroy` which is the reverse of the default and ensures the replacements are created first and then deletes the old instances.
2. Associate this with an [Auto Scaling Group (ASG)](https://aws.amazon.com/autoscaling/) by using the [`aws_autoscaling_group`](https://www.terraform.io/docs/providers/aws/r/autoscaling_group.html) resource.
2.1. `min_size` and `max_size`  specificies the boundaries of the cluster size.
2.2. `availability_zones` parameter must be specified but rather than hard-coding these use a [`aws_availability_zones`](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html) `data` source to fetch a list:
```
data "aws_availability_zones" "all" { }
```
and then within the `aws_autoscaling_group` you can use this value similar to:
```
...
  availability_zones   = data.aws_availability_zones.all.names
...
```

## Deployment of load balancer

In order to distribute the traffic to the servers within the ASG you will need a load balancer. AWS offers different types but whilst the Application Load Balancer (ALB) would be more appropriate a Classic Load Balancer (CLB) is used in this example as it is easier to configure.

1. Create a load balancer using the [`aws_elb`](https://www.terraform.io/docs/providers/aws/r/elb.html) resource.
1.1. specify the `availabilty_zones` with the same value as the ASG.
1.2. add a `listener` configuration to configure ports and routing.
1.3. as this is a CLB specifiying the `health_check` is recommended too. The "ELB" health check is much more robust that the default "EC2" health check and will detect requests not being served not just if the server is completely down.
1.4. update the ASG to point to this using its `load_balancers` parameter.
2. Add a security group to enable inbound and outbound traffic using the [`aws_security_group`](https://www.terraform.io/docs/providers/aws/r/security_group.html) resource.
2.1. Specify `egress` configuration for outbound traffic
2.2. Specify `ingress` configuration for inbound traffic
2.3. The CLB configuration should be configured with this security group
3. Adding a DNS name as an output

## References:
- [An Introduction to Terraform](https://blog.gruntwork.io/an-introduction-to-terraform-f17df9c6d180)
- [A Comprehensive Guide to Building a Scalable Web App on Amazon Web Services - Part 1](https://www.airpair.com/aws/posts/building-a-scalable-web-app-on-amazon-web-services-p1)

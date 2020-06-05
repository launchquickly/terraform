output "vpc_pulic_subnets" {
  description = "IDs of the VPC's public subnets"
  value       = module.vpc.public_subnets
}

output "ec2_instance_public_ips" {
  description = "PUblic IP addresses of EC2 instances"
  value       = module.ec2_instances.public_ip
}
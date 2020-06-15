variable "enable_autoscaling" {
  description = "If set to true, enable auto scaling"
  type        = bool
}

variable "give_neo_cloudwatch_full_access" {
  description = "If set to true, neo gets full access to CloudWatch"
  type        = bool
}

variable "user_names" {
  description = "Create IAM users with these names"
  type        = list(string)
  default     = ["neo", "trinity", "morpheus"]
}

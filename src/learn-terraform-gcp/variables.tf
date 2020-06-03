variable "project" {}

variable "environment" {
  type    = string
  default = "dev"
}


variable "credentials_file" {}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}

variable "machine_types" {
  type = map(string)
  default = {
    dev  = "f1-micro"
    test = "n1-highcpu-32"
    prod = "n1-highcpu-32"
  }
}


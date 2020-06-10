terraform {
  required_version = ">=0.12"
  
  backend "s3" {
    bucket = "lq-terraform-up-and-running-state"
    key    = "workspaces-example/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}

provider "aws" {
  version = "~> 2.65"
  region  = "us-east-2"
}

resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = (
    terraform.workspace == "default"
    ? "t2.medium"
    : "t2.micro"
    )

}
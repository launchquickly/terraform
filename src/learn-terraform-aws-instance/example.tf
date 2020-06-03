terraform {
  backend "remote" {
    organization = "launchquickly"

    workspaces {
      name = "Example-Workspace"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = var.region
}

resource "aws_instance" "example" {
  ami           = var.amis[var.region]
  instance_type = "t2.micro"
}

output "ami" {
  value = aws_instance.example.ami
}

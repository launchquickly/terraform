terraform {
  required_version = ">=0.12"

  backend "s3" {
    bucket = "lq-terraform-up-and-running-state"
    key    = "stage/data-storage/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_db_instance" "example" {
  identifier_prefix = "terraform-up-and-running"
  engine            = "mysql"
  allocated_storage = 10
  instance_class    = "db.t2.micro"
  name              = "example_database"
  username          = "admin"
  password          = "password"

  # Don't copy this to your production examples. It's only here to make it quicker to delete this DB.
  skip_final_snapshot = true
}
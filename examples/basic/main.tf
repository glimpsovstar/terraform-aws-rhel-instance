# Minimal usage: an instance in an existing VPC and subnet.

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "ap-southeast-2"
}

variable "vpc_id" { type = string }
variable "subnet_id" { type = string }
variable "key_pair_name" { type = string }

module "instance" {
  source = "../../"

  instance_name = "example-basic"
  vpc_id        = var.vpc_id
  subnet_id     = var.subnet_id
  key_pair_name = var.key_pair_name
}

output "public_ip" {
  value = module.instance.public_ip
}

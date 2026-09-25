# Full-featured usage: governance tags, a larger size, and the Vault SSH CA
# installed so automation connects with short-lived signed certificates.

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "vault" {}

variable "aws_region" {
  type    = string
  default = "ap-southeast-2"
}

variable "vpc_id" { type = string }
variable "subnet_id" { type = string }
variable "key_pair_name" { type = string }

data "vault_generic_secret" "ssh_ca" {
  path = "ssh/config/ca"
}

module "instance" {
  source = "../../"

  instance_name    = "example-complete"
  environment      = "Prod"
  instance_size    = "Medium"
  root_volume_size = 50

  vpc_id           = var.vpc_id
  subnet_id        = var.subnet_id
  key_pair_name    = var.key_pair_name
  ssh_ingress_cidr = "10.0.0.0/16"

  vault_ssh_ca_public_key = data.vault_generic_secret.ssh_ca.data["public_key"]

  tags = {
    ProjectCode  = "HA-2026-091"
    BusinessUnit = "Border Systems"
    SNRequest    = "RITM0012345"
    RequestedBy  = "david.joo"
  }
}

output "instance_id" {
  value = module.instance.instance_id
}

output "tags" {
  value = module.instance.tags
}

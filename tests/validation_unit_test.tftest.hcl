# Contract tests: the module must reject inputs that violate its promises.

mock_provider "aws" {
  mock_data "aws_ami" {
    defaults = {
      id = "ami-00000000000000000"
    }
  }
}

variables {
  instance_name = "ha-demo-001"
  vpc_id        = "vpc-0123456789abcdef0"
  subnet_id     = "subnet-0123456789abcdef0"
  key_pair_name = "demo-key"
}

run "rejects_uppercase_instance_name" {
  command = plan

  variables {
    instance_name = "HA-Demo-001"
  }

  expect_failures = [var.instance_name]
}

run "rejects_unknown_environment" {
  command = plan

  variables {
    environment = "Staging"
  }

  expect_failures = [var.environment]
}

run "rejects_unknown_instance_size" {
  command = plan

  variables {
    instance_size = "XLarge"
  }

  expect_failures = [var.instance_size]
}

run "rejects_malformed_ssh_cidr" {
  command = plan

  variables {
    ssh_ingress_cidr = "not-a-cidr"
  }

  expect_failures = [var.ssh_ingress_cidr]
}

run "rejects_undersized_root_volume" {
  command = plan

  variables {
    root_volume_size = 4
  }

  expect_failures = [var.root_volume_size]
}

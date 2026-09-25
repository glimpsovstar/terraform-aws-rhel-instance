# Integration test. Creates and destroys REAL AWS resources.
#
# Deliberately kept out of tests/ so `terraform test` in CI does not run it.
# Run explicitly, with AWS credentials and real network IDs:
#
#   terraform test -test-directory=tests-integration \
#     -var=vpc_id=vpc-... -var=subnet_id=subnet-... -var=key_pair_name=...
#
# Terraform destroys everything it created when the file finishes, including
# on failure.

# A module must not configure its own provider, so the integration run
# configures it here. Region and credentials come from the environment, which
# aws-actions/configure-aws-credentials sets from the assumed role.
provider "aws" {}

variables {
  instance_name = "tftest-integration"
  environment   = "Dev"
  instance_size = "Small"
  application   = "module-integration-test"
}

run "instance_really_builds" {
  command = apply

  assert {
    condition     = aws_instance.this.id != ""
    error_message = "The instance must actually be created."
  }

  assert {
    condition     = aws_instance.this.instance_state == "running"
    error_message = "The instance must reach the running state."
  }

  assert {
    condition     = output.public_ip != null && output.public_ip != ""
    error_message = "A public IP must be assigned when associate_public_ip_address is true."
  }

  assert {
    condition     = output.instance_type == "t3.micro"
    error_message = "Small must really produce a t3.micro, not just plan as one."
  }
}

run "security_group_really_restricts_ssh" {
  command = apply

  assert {
    condition     = aws_vpc_security_group_ingress_rule.ssh[0].cidr_ipv4 == "192.168.0.0/24"
    error_message = "SSH ingress must be created with the restricted CIDR."
  }

  assert {
    condition     = output.security_group_id != null
    error_message = "The security group must exist and be reported."
  }
}

run "ami_lookup_really_resolves_a_rhel9_image" {
  command = apply

  assert {
    condition     = can(regex("^ami-", output.ami_id))
    error_message = "The AMI lookup must resolve to a real AMI ID."
  }
}

# Unit tests. mock_provider keeps these runnable in CI with no cloud
# credentials and no billable resources.

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

run "defaults_are_small_encrypted_and_imdsv2" {
  command = plan

  assert {
    condition     = aws_instance.this.instance_type == "t3.small"
    error_message = "Small must resolve to t3.small."
  }

  assert {
    condition     = aws_instance.this.root_block_device[0].encrypted == true
    error_message = "Root volume must be encrypted by default."
  }

  assert {
    condition     = aws_instance.this.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 must be required."
  }
}

run "ssh_is_not_open_to_the_world_by_default" {
  command = plan

  assert {
    condition     = aws_vpc_security_group_ingress_rule.ssh[0].cidr_ipv4 != "0.0.0.0/0"
    error_message = "Default SSH ingress must not be the entire internet."
  }
}

run "medium_resolves_to_t3_medium" {
  command = plan

  variables {
    instance_size = "Medium"
  }

  assert {
    condition     = aws_instance.this.instance_type == "t3.medium"
    error_message = "Medium must resolve to t3.medium."
  }
}

run "tags_carry_name_and_environment" {
  command = plan

  variables {
    environment = "Prod"
    tags        = { ProjectCode = "HA-2026-091" }
  }

  assert {
    condition     = aws_instance.this.tags["Name"] == "ha-demo-001"
    error_message = "Name tag must be set from instance_name."
  }

  assert {
    condition     = aws_instance.this.tags["Environment"] == "Prod"
    error_message = "Environment tag must be set."
  }

  assert {
    condition     = aws_instance.this.tags["ProjectCode"] == "HA-2026-091"
    error_message = "Caller-supplied tags must be merged, not dropped."
  }
}

run "security_group_can_be_disabled" {
  command = plan

  variables {
    create_security_group         = false
    additional_security_group_ids = ["sg-0123456789abcdef0"]
  }

  assert {
    condition     = length(aws_security_group.this) == 0
    error_message = "No security group should be created when create_security_group is false."
  }
}

run "vault_ca_produces_user_data" {
  command = plan

  variables {
    vault_ssh_ca_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB dummy"
  }

  assert {
    condition     = aws_instance.this.user_data != null
    error_message = "Supplying a Vault SSH CA key must produce user_data installing it."
  }
}

# Coverage for paths the defaults tests do not reach.

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

run "large_resolves_to_t3_medium" {
  command = plan

  variables {
    instance_size = "Large"
  }

  assert {
    condition     = aws_instance.this.instance_type == "t3.medium"
    error_message = "Large must resolve to t3.medium."
  }
}

run "explicit_ami_overrides_the_lookup" {
  command = plan

  variables {
    ami_id = "ami-0fedcba987654321f"
  }

  assert {
    condition     = aws_instance.this.ami == "ami-0fedcba987654321f"
    error_message = "A supplied ami_id must be used instead of the lookup."
  }

  assert {
    condition     = length(data.aws_ami.rhel9) == 0
    error_message = "The AMI data source must not be evaluated when ami_id is supplied."
  }
}

run "no_vault_ca_means_no_user_data" {
  command = plan

  assert {
    condition     = aws_instance.this.user_data == null
    error_message = "Without a CA key there should be no user_data at all."
  }
}

# With create_security_group = false every ID is known at plan time, so this
# asserts the merge deterministically. The created group's ID is unknown until
# apply, which makes the combined set unknowable in plan mode.
run "supplied_security_groups_are_attached_verbatim" {
  command = plan

  variables {
    create_security_group         = false
    additional_security_group_ids = ["sg-0aaaaaaaaaaaaaaaa", "sg-0bbbbbbbbbbbbbbbb"]
  }

  assert {
    condition     = length(aws_instance.this.vpc_security_group_ids) == 2
    error_message = "Both supplied security groups must be attached."
  }

  assert {
    condition     = contains(aws_instance.this.vpc_security_group_ids, "sg-0aaaaaaaaaaaaaaaa")
    error_message = "Supplied security group IDs must be passed through unchanged."
  }
}

run "created_security_group_is_added_to_the_instance" {
  command = plan

  variables {
    additional_security_group_ids = ["sg-0aaaaaaaaaaaaaaaa"]
  }

  assert {
    condition     = length(aws_security_group.this) == 1
    error_message = "A security group should be created by default."
  }

  assert {
    condition     = aws_security_group.this[0].vpc_id == "vpc-0123456789abcdef0"
    error_message = "The created group must live in the supplied VPC."
  }
}

run "private_placement_drops_the_public_ip" {
  command = plan

  variables {
    associate_public_ip_address = false
  }

  assert {
    condition     = aws_instance.this.associate_public_ip_address == false
    error_message = "associate_public_ip_address must be honoured for private placement."
  }
}

run "iam_instance_profile_is_attached_when_supplied" {
  command = plan

  variables {
    iam_instance_profile = "tfstacks-profile"
  }

  assert {
    condition     = aws_instance.this.iam_instance_profile == "tfstacks-profile"
    error_message = "A supplied instance profile must be attached."
  }
}

run "custom_root_volume_size_is_honoured" {
  command = plan

  variables {
    root_volume_size = 100
  }

  assert {
    condition     = aws_instance.this.root_block_device[0].volume_size == 100
    error_message = "root_volume_size must reach the root block device."
  }

  assert {
    condition     = aws_instance.this.root_block_device[0].volume_type == "gp3"
    error_message = "Root volume must stay gp3."
  }
}

run "custom_ansible_user_appears_in_user_data" {
  command = plan

  variables {
    vault_ssh_ca_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB dummy"
    ansible_user            = "automation"
  }

  assert {
    condition     = strcontains(aws_instance.this.user_data, "automation")
    error_message = "A custom ansible_user must be the user created in user_data."
  }
}

run "required_tags_are_always_present" {
  command = plan

  assert {
    condition = alltrue([
      for t in ["Name", "Environment", "Application", "ManagedBy"] :
      contains(keys(aws_instance.this.tags), t)
    ])
    error_message = "Every tag the organisation's tflint ruleset requires must be present."
  }
}

# HashiCorp approved base images, not Red Hat's public account.
#
# The approved base carries the Uptycs EDR agent, which is what satisfies
# HC-COMPUTE-011. Building from Red Hat's public RHEL 9 produces an instance
# with no EDR and gets flagged by security - see pkr-RHEL9-SOE commit a40e12a,
# which made this same correction for the SOE image.
data "aws_ami" "rhel9" {
  count = var.ami_id == "" ? 1 : 0

  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name        = "${var.instance_name}-sg"
  description = "Self-service instance ${var.instance_name} (${var.environment})"
  vpc_id      = var.vpc_id

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  count = var.create_security_group ? 1 : 0

  security_group_id = aws_security_group.this[0].id
  description       = "SSH from the approved range only"
  cidr_ipv4         = var.ssh_ingress_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"

  tags = local.tags
}

resource "aws_vpc_security_group_egress_rule" "all" {
  count = var.create_security_group ? 1 : 0

  security_group_id = aws_security_group.this[0].id
  description       = "All outbound"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = local.tags
}

resource "aws_instance" "this" {
  ami                         = local.ami_id
  instance_type               = local.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = local.security_group_ids
  key_name                    = var.key_pair_name
  associate_public_ip_address = var.associate_public_ip_address
  iam_instance_profile        = var.iam_instance_profile != "" ? var.iam_instance_profile : null
  user_data                   = local.user_data

  root_block_device {
    encrypted   = true
    volume_size = var.root_volume_size
    volume_type = "gp3"
    tags        = local.tags
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2 only
  }

  tags = local.tags
}

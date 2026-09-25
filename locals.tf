locals {
  # T-shirt sizes keep consumer-facing choices readable and stop requesters
  # inventing instance types nobody costed or approved.
  instance_type = {
    Small  = "t3.micro"
    Medium = "t3.small"
    Large  = "t3.medium"
  }[var.instance_size]

  ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.rhel9[0].id

  security_group_ids = concat(
    var.create_security_group ? [aws_security_group.this[0].id] : [],
    var.additional_security_group_ids,
  )

  tags = merge(
    var.tags,
    {
      Name        = var.instance_name
      Environment = var.environment
      Application = var.application
      ManagedBy   = var.managed_by
      Terraform   = "true"
    },
  )

  # Installs the Vault SSH CA as a trusted user CA so automation connects with
  # a short-lived signed certificate rather than a key stored on the host.
  user_data = var.vault_ssh_ca_public_key == "" ? null : <<-EOT
    #!/bin/bash
    set -euo pipefail

    id -u "${var.ansible_user}" &>/dev/null || useradd -m -s /bin/bash "${var.ansible_user}"
    echo "${var.ansible_user} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${var.ansible_user}"
    chmod 440 "/etc/sudoers.d/${var.ansible_user}"

    cat > /etc/ssh/trusted-user-ca-keys.pem <<'CAKEY'
    ${var.vault_ssh_ca_public_key}
    CAKEY
    chmod 644 /etc/ssh/trusted-user-ca-keys.pem

    grep -q '^TrustedUserCAKeys' /etc/ssh/sshd_config \
      || echo 'TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem' >> /etc/ssh/sshd_config

    systemctl restart sshd
  EOT
}

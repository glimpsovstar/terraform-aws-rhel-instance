# terraform-aws-rhel-instance

A RHEL 9 EC2 instance with a security group, governance tags, and optional trust of a
Vault SSH CA so automation connects with short-lived signed certificates instead of a key
stored on the host.

Knows nothing about Ansible. Pair it with
[`terraform-aap-postdeploy`](https://github.com/glimpsovstar/terraform-aap-postdeploy) to
register the host with Ansible Automation Platform and run a post-deployment workflow.

## Usage

```hcl
module "instance" {
  source  = "app.terraform.io/djoo-hashicorp/rhel-instance/aws"
  version = "~> 1.0"

  instance_name = "ha-demo-001"
  environment   = "Dev"
  instance_size = "Small"

  vpc_id        = var.vpc_id
  subnet_id     = var.subnet_id
  key_pair_name = var.key_pair_name

  vault_ssh_ca_public_key = data.vault_generic_secret.ssh_ca.data["public_key"]

  tags = {
    ProjectCode  = "HA-2026-091"
    BusinessUnit = "Border Systems"
    SNRequest    = "RITM0012345"
  }
}
```

**Placement is an input, not a lookup.** The module takes `vpc_id` and `subnet_id` rather
than discovering them, so the caller decides whether they come from remote state, data
sources, or literals. That is what lets the same module serve a long-lived workspace and a
per-request self-service workspace without either inheriting the other's assumptions.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `instance_name` | string | — | 3–32 lowercase alphanumeric/hyphen. Becomes the `Name` tag |
| `vpc_id` | string | — | VPC for the instance and its security group |
| `subnet_id` | string | — | Subnet to place the instance in |
| `key_pair_name` | string | — | Existing EC2 key pair, for break-glass access |
| `environment` | string | `Dev` | `Dev`, `Test` or `Prod` |
| `instance_size` | string | `Small` | `Small`, `Medium`, `Large` |
| `root_volume_size` | number | `20` | GiB, 10–1000 |
| `ami_id` | string | `""` | Empty looks up the latest Red Hat published RHEL 9 |
| `ssh_ingress_cidr` | string | `192.168.0.0/24` | CIDR allowed to reach SSH |
| `vault_ssh_ca_public_key` | string | `""` | When set, `user_data` installs it as a trusted user CA |
| `ansible_user` | string | `aap` | Automation user created and trusted against the CA |
| `additional_security_group_ids` | list(string) | `[]` | Extra groups to attach |
| `iam_instance_profile` | string | `""` | Instance profile, empty for none |
| `create_security_group` | bool | `true` | Set false to rely only on supplied groups |
| `associate_public_ip_address` | bool | `true` | Disable for private-subnet placement |
| `application` | string | `unassigned` | `Application` tag |
| `managed_by` | string | `Terraform` | `ManagedBy` tag |
| `tags` | map(string) | `{}` | Merged into every resource |

## Outputs

`instance_id` · `public_ip` · `private_ip` · `hostname` · `instance_type` · `ami_id` ·
`security_group_id` · `tags`

## Secure defaults

| Control | Default |
|---|---|
| Root volume | encrypted `gp3` |
| Instance metadata | IMDSv2 required (`http_tokens = "required"`) |
| SSH ingress | `192.168.0.0/24`, never `0.0.0.0/0` |
| Host access | Vault-signed SSH certificates when a CA key is supplied |

Widening `ssh_ingress_cidr` is a deliberate decision by the caller, not a default.

## Development

```bash
terraform fmt -check -recursive
terraform init -backend=false && terraform validate
tflint --recursive
terraform test          # 11 tests, mock_provider, no cloud credentials needed
```

Tests run against `mock_provider`, so CI needs no AWS access and creates nothing billable.

## Examples

- [`examples/basic`](examples/basic) — minimal
- [`examples/complete`](examples/complete) — governance tags, larger size, Vault SSH CA

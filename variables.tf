# ---------------------------------------------------------------------------
# Identity
# ---------------------------------------------------------------------------

variable "instance_name" {
  description = "Short name for the instance. Used for the Name tag and derived resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,30}[a-z0-9]$", var.instance_name))
    error_message = "Must be 3-32 characters of lowercase letters, numbers or hyphens, starting and ending alphanumeric."
  }
}

variable "environment" {
  description = "Target environment. Applied as the Environment tag."
  type        = string
  default     = "Dev"

  validation {
    condition     = contains(["Dev", "Test", "Prod"], var.environment)
    error_message = "Environment must be one of: Dev, Test, Prod."
  }
}

# ---------------------------------------------------------------------------
# Placement - supplied by the caller so the root decides how to source them
# (remote state, data sources, or literals).
# ---------------------------------------------------------------------------

variable "vpc_id" {
  description = "VPC the instance and its security group are created in."
  type        = string
}

variable "subnet_id" {
  description = "Subnet the instance is placed in."
  type        = string
}

# ---------------------------------------------------------------------------
# Sizing
# ---------------------------------------------------------------------------

variable "instance_size" {
  description = "T-shirt size. Resolved to an EC2 instance type by the module."
  type        = string
  default     = "Small"

  validation {
    condition     = contains(["Small", "Medium", "Large"], var.instance_size)
    error_message = "Instance size must be one of: Small, Medium, Large."
  }
}

variable "root_volume_size" {
  description = "Root volume size in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 10 && var.root_volume_size <= 1000
    error_message = "Root volume size must be between 10 and 1000 GiB."
  }
}

variable "ami_id" {
  description = "AMI to launch. Leave empty to look up the latest Red Hat published RHEL 9 image."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Access - no defaults on security-sensitive inputs that grant reach
# ---------------------------------------------------------------------------

variable "key_pair_name" {
  description = "Existing EC2 key pair name for break-glass access."
  type        = string
}

variable "ssh_ingress_cidr" {
  description = "CIDR permitted to reach SSH. Deliberately narrow; widening this is a security decision."
  type        = string
  default     = "192.168.0.0/24"

  validation {
    condition     = can(cidrhost(var.ssh_ingress_cidr, 0))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}

variable "vault_ssh_ca_public_key" {
  description = "Vault SSH CA public key. When set, user_data installs it as a trusted user CA so AAP can connect with short-lived signed certificates instead of a stored key."
  type        = string
  default     = ""
}

variable "ansible_user" {
  description = "Local user created for automation, trusted against the Vault SSH CA."
  type        = string
  default     = "aap"
}

variable "additional_security_group_ids" {
  description = "Extra security groups to attach alongside the one this module creates."
  type        = list(string)
  default     = []
}

variable "iam_instance_profile" {
  description = "IAM instance profile to attach. Empty means none."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Behaviour
# ---------------------------------------------------------------------------

variable "create_security_group" {
  description = "Create a security group for this instance. Set false to rely entirely on additional_security_group_ids."
  type        = bool
  default     = true
}

variable "associate_public_ip_address" {
  description = "Associate a public IP. Disable for private-subnet placement."
  type        = bool
  default     = true
}

variable "application" {
  description = "Application or service this instance belongs to. Applied as the Application tag, which the organisation's tflint ruleset requires."
  type        = string
  default     = "unassigned"
}

variable "managed_by" {
  description = "What manages this resource's lifecycle. Applied as the ManagedBy tag."
  type        = string
  default     = "Terraform"
}

variable "tags" {
  description = "Tags applied to every resource this module creates."
  type        = map(string)
  default     = {}
}

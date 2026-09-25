output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Public IP address, or null when no public IP was associated."
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "Private IP address."
  value       = aws_instance.this.private_ip
}

output "hostname" {
  description = "Instance name, suitable for use as an inventory host name."
  value       = var.instance_name
}

output "instance_type" {
  description = "EC2 instance type the chosen size resolved to."
  value       = aws_instance.this.instance_type
}

output "ami_id" {
  description = "AMI the instance was launched from."
  value       = local.ami_id
}

output "security_group_id" {
  description = "ID of the security group this module created, or null when create_security_group is false."
  value       = var.create_security_group ? aws_security_group.this[0].id : null
}

output "tags" {
  description = "Tags applied to every resource, for audit and downstream reuse."
  value       = local.tags
}

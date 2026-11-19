output "autoscaling_group_arn" {
  value = aws_autoscaling_group.this.arn
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.this.name
}

output "launch_template_id" {
  value = aws_launch_template.this.id
}

output "launch_template_latest_version" {
  value = aws_launch_template.this.latest_version
}

output "cloudinit_required_permissions" {
  description = "IAM permissions required by cloud-init artifacts (S3, etc.). Attach to your instance role. Null values mean that provider's scheme is not used."
  value       = module.cloudinit.required_permissions
}

output "topology_fragment" {
  description = "Network topology fragment for composition with sibling modules via provider::netutils::mermaid_merge(). See terraform-provider-netutils's docs/topology-fragment-spec.md."
  value       = local.topology_fragment
}

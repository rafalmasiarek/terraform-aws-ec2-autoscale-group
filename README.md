# terraform-aws-ec2-autoscale-group

Generic Terraform module for an EC2 launch template + Auto Scaling Group. No knowledge of any particular AWS service that might run on top (ECS, EKS, or anything else) - all configuration comes from the caller, including the AMI (no internal `data "aws_ami"` lookup deciding anything on your behalf).

## Usage

```hcl
module "nodes" {
  source = "git::https://github.com/rafalmasiarek/terraform-aws-ec2-autoscale-group.git?ref=v0.1.0"

  name          = "my-nodes"
  ami_id        = data.aws_ssm_parameter.ecs_ami.value
  instance_type = "t3.medium"

  subnet_ids                  = module.subnets.subnet_ids_by_tier["public"]
  vpc_security_group_ids      = [aws_security_group.nodes.id]
  associate_public_ip_address = true

  min_size         = 0
  max_size         = 3
  desired_capacity = 1

  tagger_context = module.tagger.context
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | - | Name for the launch template, ASG, and tagger name. |
| `ami_id` | `string` | - | AMI to launch. Resolved by the caller, never by this module. |
| `instance_type` | `string` | - | Ignored per-override if `mixed_instances_policy` sets its own. |
| `key_name` | `string` | `null` | |
| `iam_instance_profile_name` | `string` | `null` | Name of an existing IAM instance profile. No profile attached if `null`. |
| `cloudinit_config` | `any` | `{}` | Wildcard passthrough to every input of [terraform-null-cloudinit](https://github.com/rafalmasiarek/terraform-null-cloudinit) (`cloud_config`, `packages`, `users`, `files`, `mounts`, `ansible_pull`, `artifacts`, `ansible_playbooks`, ...) - see that module's README for the full field set. |
| `ebs_optimized` | `bool` | `null` | |
| `disable_api_termination` | `bool` | `null` | |
| `instance_initiated_shutdown_behavior` | `string` | `null` | `"stop"` or `"terminate"`. |
| `update_default_version` | `bool` | `true` | Set the newest launch template version as the default on every change. |
| `launch_template_version` | `string` | `"$Latest"` | Version the ASG launches from. |
| `enable_monitoring` | `bool` | `true` | Detailed (1-minute) CloudWatch monitoring. |
| `metadata_options` | `object` | IMDSv2 enforced | `http_endpoint`, `http_tokens`, `http_put_response_hop_limit`. |
| `block_device_mappings` | `list(object)` | `[]` | `device_name`, `ebs {...}`. |
| `cpu_options` | `object` | `null` | `core_count`, `threads_per_core`, `amd_sev_snp`, `nested_virtualization`. |
| `credit_specification` | `string` | `null` | `cpu_credits`: `"standard"` or `"unlimited"` - T-class instances only. |
| `placement` | `object` | `null` | `affinity`, `availability_zone`, `group_name`, `host_id`, `host_resource_group_arn`, `spread_domain`, `tenancy`, `partition_number`. |
| `license_specifications` | `list(object)` | `[]` | `license_configuration_arn`. |
| `vpc_security_group_ids` | `list(string)` | `[]` | Ignored if `network_interfaces` is set. |
| `associate_public_ip_address` | `bool` | `false` | Needed to reach the internet without a NAT Gateway in a public subnet. Ignored if `network_interfaces` is set. |
| `network_interfaces` | `list(object)` | `[]` | Advanced override: full control over every ENI (e.g. multiple interfaces). Leave empty for the common one-ENI case built from the two inputs above. |
| `tag_specifications_resource_types` | `list(string)` | `["instance", "volume", "network-interface"]` | Which launch-template `tag_specifications` blocks to emit. |
| `subnet_ids` | `list(string)` | - | |
| `min_size` / `max_size` | `number` | - | |
| `desired_capacity` | `number` | `null` | |
| `health_check_type` | `string` | `"EC2"` | |
| `health_check_grace_period` | `number` | `null` | |
| `protect_from_scale_in` | `bool` | `false` | Required `true` for ECS `managed_termination_protection` to work when this ASG backs an ECS capacity provider. |
| `force_delete` | `bool` | `false` | |
| `termination_policies` | `list(string)` | `[]` | |
| `suspended_processes` | `list(string)` | `[]` | |
| `mixed_instances_policy` | `object` | `null` | On-demand/spot mix. `null` = plain single-instance-type ASG using `instance_type`/`ami_id` directly. |
| `instance_refresh` | `object` | `null` | `strategy`, `preferences { min_healthy_percentage }`. |
| `autoscaling_group_tags` | `map(string)` | `{}` | Extra ASG tags on top of the tagger's own. |
| `autoscaling_policies_enabled` | `bool` | `false` | Create CPU-based scale-up/down policies + CloudWatch alarms. Unrelated to ECS capacity-provider managed scaling. |
| `scale_up_policy` / `scale_down_policy` | `object` | see below | `scaling_adjustment`, `adjustment_type`, `cooldown_seconds`. |
| `cpu_alarm_high` / `cpu_alarm_low` | `object` | see below | `threshold_percent`, `period_seconds`, `evaluation_periods`. |
| `use_tagger` | `bool` | `true` | `false` applies `var.tags` as-is instead. |
| `tagger_context` | `any` | `null` | `module.tagger.context` from the root stack. |
| `tags` | `map(string)` | `{}` | Custom tags for the resources. |

`scale_up_policy` defaults: `scaling_adjustment = 1`, `adjustment_type = "ChangeInCapacity"`, `cooldown_seconds = 300`. `scale_down_policy` defaults: `scaling_adjustment = -1`, same adjustment type/cooldown. `cpu_alarm_high` defaults: `threshold_percent = 80`, `period_seconds = 300`, `evaluation_periods = 2`. `cpu_alarm_low` defaults: `threshold_percent = 20`, same period/evaluation_periods.

## Outputs

| Name | Description |
|---|---|
| `autoscaling_group_arn` | |
| `autoscaling_group_name` | |
| `launch_template_id` | |
| `launch_template_latest_version` | |

## Public IP in a public subnet

`associate_public_ip_address` always goes through a single `network_interfaces` block rather than the launch template's flat `vpc_security_group_ids` attribute - that combination has a long-standing AWS provider quirk ([terraform-provider-aws#4570](https://github.com/hashicorp/terraform-provider-aws/issues/4570)) where `associate_public_ip_address` doesn't reliably apply otherwise. Set `network_interfaces` yourself only for advanced cases (e.g. multiple ENIs) - it fully overrides `vpc_security_group_ids`/`associate_public_ip_address` when set.

## User data

`cloudinit_config` is a single wildcard object forwarded as-is into every input of [terraform-null-cloudinit](https://github.com/rafalmasiarek/terraform-null-cloudinit) - this module never needs a new variable when that one gains a new helper, only one new `try()` line in its own `main.tf`. A plain shell script is just:

```hcl
cloudinit_config = {
  shell_scripts = ["#!/bin/bash\necho hello\n"]
}
```

See that module's README for the full catalog (packages, users, files, mounts, ansible, S3/HTTPS artifacts, ...).

## Tagging

Both the launch template and the ASG share one tagger entry (`terraform-null-tagger`'s `autoscaling_group` service category: `min_size`, `max_size`). CPU alarms, if enabled, carry the same tags. Set `use_tagger = false` to bypass this and apply `var.tags` directly instead.

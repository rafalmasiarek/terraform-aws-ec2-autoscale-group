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
| `identity` | `object` | `{mode = "none"}` | Instance naming strategy: `mode = "none"` (default, no change in behavior), `"aws_native"` (launch template's private DNS hostname), `"static"` (feeds `identity.static.hostname`/`fqdn` into CloudInit), `"custom_runtime"` (per-instance hostname generated at boot from a template + IMDSv2). See [Instance identity](#instance-identity). |
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

## Instance identity

`identity.mode` picks which component owns an instance's hostname/DNS - exactly one authority per mode, enforced by a precondition so two mechanisms never fight over the same name:

- **`"none"`** (default) - no change. Use `cloudinit_config.hostname`/`fqdn`/`preserve_hostname` directly, as before.
- **`"aws_native"`** - configures the launch template's `private_dns_name_options` (an AWS EC2/VPC feature, not CloudInit): `hostname_type` (`"ip-name"` or `"resource-name"`), `enable_resource_name_dns_a_record`, `enable_resource_name_dns_aaaa_record`. Recommended for AWS-native environments - no bootstrap script needed. Setting `cloudinit_config.hostname` at the same time is rejected.

  ```hcl
  identity = {
    mode = "aws_native"
    aws_native = {
      hostname_type                     = "resource-name"
      enable_resource_name_dns_a_record = true
    }
  }
  ```

- **`"static"`** - for a single, fixed-identity instance (e.g. a standalone database box). Equivalent to setting `cloudinit_config.hostname`/`fqdn` directly - `identity.mode` just documents that choice explicitly. Setting `cloudinit_config.hostname` at the same time is rejected.

  ```hcl
  identity = {
    mode = "static"
    static = {
      hostname = "db-production-01"
      fqdn     = "db-production-01.internal.example.com"
    }
  }
  ```

- **`"custom_runtime"`** - per-instance hostname generated at boot, for naming conventions AWS-native naming doesn't cover. Safe for any ASG size - each instance computes its own hostname independently. `hostname_template` mixes two kinds of `{token}`: static ones resolved at `terraform plan` from `identity.custom_runtime.variables` (e.g. `service`, `environment`), and runtime ones resolved at boot from IMDSv2 - `instance_id`, `private_ipv4`, `private_ipv6`, `availability_zone`, `region`. Only the runtime tokens actually referenced are queried - the bootstrap script never fetches metadata the template doesn't use. Requires `metadata_options.http_tokens = "required"` (the module's own default).

  ```hcl
  identity = {
    mode = "custom_runtime"
    custom_runtime = {
      hostname_template = "{service}-{environment}-{instance_id}"
      domain             = "internal.example.com"
      variables = {
        service     = "api"
        environment = "production"
      }
    }
  }
  ```

  The generated hostname is lowercased, stripped to `[a-z0-9-]`, and truncated to 63 characters (DNS label limit) if needed - preserving uniqueness via a stable suffix from the tail of the truncated value rather than a naive cut. If a referenced runtime value can't be fetched (e.g. `private_ipv6` on an IPv4-only instance), the bootstrap script logs to `/var/log/identity-bootstrap.log` and skips hostname-setting entirely rather than applying a broken or partial name. `domain`, if set, only adds a local `/etc/hosts` entry for the FQDN - never a real DNS record (see below).

  This mode calls `hostnamectl set-hostname` directly rather than going through CloudInit's own `hostname`/`fqdn` handling, since that mechanism only accepts a literal string known when `user_data` is rendered - it has no way to query IMDS itself. Assumes a systemd-based AMI (Amazon Linux 2023, Ubuntu, RHEL9, and similar) - if `hostnamectl` isn't present, the failure is logged and the instance keeps whatever hostname it already had.

There is no public-hostname equivalent to configure: AWS has no per-instance "public hostname type" setting at the launch-template level. Public DNS resolution of an instance is governed entirely by the VPC's `enable_dns_hostnames` (see [terraform-aws-vpc](https://github.com/rafalmasiarek/terraform-aws-vpc)) and whether the instance has a public IP, which is already controlled by `associate_public_ip_address`/`network_interfaces` above.

This module never creates DNS records, PTR entries, or service-discovery registrations for individual instances - an ASG's instances are replaced outside of any `terraform apply`, so per-instance DNS is an external DNS mechanism's responsibility, not this module's.

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

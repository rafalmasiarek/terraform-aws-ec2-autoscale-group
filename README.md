# terraform-aws-ec2-autoscale-group








## About

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


## Terraform Reference



### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |
| <a name="requirement_tagger"></a> [tagger](#requirement\_tagger) | >= 0.1.0 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloudinit"></a> [cloudinit](#module\_cloudinit) | rafalmasiarek/cloudinit/null | ~> 0.2.0 |
| <a name="module_tagger"></a> [tagger](#module\_tagger) | rafalmasiarek/tagger/null | >= 0.5.0 |

### Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_lifecycle_hook.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_lifecycle_hook) | resource |
| [aws_autoscaling_policy.scale_down](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_autoscaling_policy.scale_up](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_cloudwatch_metric_alarm.cpu_high](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.cpu_low](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_launch_template.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| tagger_origin.self | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI to launch. No default, no internal data source - resolve it in the caller's own stack. | `string` | n/a | yes |
| <a name="input_associate_public_ip_address"></a> [associate\_public\_ip\_address](#input\_associate\_public\_ip\_address) | Assign a public IP to instances launched from this template - needed to reach the internet (pull images, etc.) without a NAT Gateway when running in a public subnet. Ignored if network\_interfaces is set. | `bool` | `false` | no |
| <a name="input_autoscaling_group_tags"></a> [autoscaling\_group\_tags](#input\_autoscaling\_group\_tags) | Extra ASG tags on top of the tagger's own - merged, tagger wins on conflict. | `map(string)` | `{}` | no |
| <a name="input_autoscaling_policies_enabled"></a> [autoscaling\_policies\_enabled](#input\_autoscaling\_policies\_enabled) | Create CPU-based scale-up/scale-down policies and CloudWatch alarms for this ASG. Unrelated to ECS capacity-provider managed scaling - this is plain EC2-metric-based autoscaling, independent of whatever consumes the ASG. | `bool` | `false` | no |
| <a name="input_block_device_mappings"></a> [block\_device\_mappings](#input\_block\_device\_mappings) | n/a | <pre>list(object({<br/>    device_name = string<br/>    ebs = optional(object({<br/>      delete_on_termination = optional(bool)<br/>      encrypted             = optional(bool)<br/>      iops                  = optional(number)<br/>      kms_key_id            = optional(string)<br/>      snapshot_id           = optional(string)<br/>      throughput            = optional(number)<br/>      volume_size           = optional(number)<br/>      volume_type           = optional(string)<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_cloudinit_config"></a> [cloudinit\_config](#input\_cloudinit\_config) | Typed pass-through to terraform-null-cloudinit. Every field mirrors that module's variables.tf exactly - see https://github.com/rafalmasiarek/terraform-null-cloudinit for full documentation. | <pre>object({<br/>    cloud_config  = optional(any)<br/>    shell_scripts = optional(list(string), [])<br/>    cloudinit_parts = optional(list(object({<br/>      content_type = string<br/>      content      = string<br/>      filename     = optional(string)<br/>      merge_type   = optional(string)<br/>    })), [])<br/>    gzip      = optional(bool, false)<br/>    max_bytes = optional(number, 16384)<br/>    scripts = optional(object({<br/>      per_boot     = optional(list(string), [])<br/>      per_instance = optional(list(string), [])<br/>      per_once     = optional(list(string), [])<br/>      boothook     = optional(list(string), [])<br/>    }), {})<br/>    packages = optional(object({<br/>      install            = optional(any, [])<br/>      update             = optional(bool, false)<br/>      upgrade            = optional(bool, false)<br/>      reboot_if_required = optional(bool, false)<br/>    }))<br/>    users = optional(list(object({<br/>      name                = string<br/>      gecos               = optional(string)<br/>      groups              = optional(list(string))<br/>      shell               = optional(string)<br/>      sudo                = optional(string)<br/>      lock_passwd         = optional(bool, true)<br/>      ssh_authorized_keys = optional(list(string))<br/>      ssh_import_id       = optional(list(string))<br/>      passwd              = optional(string)<br/>      hashed_passwd       = optional(string)<br/>      plain_text_passwd   = optional(string)<br/>      system              = optional(bool, false)<br/>      uid                 = optional(number)<br/>      primary_group       = optional(string)<br/>      homedir             = optional(string)<br/>      no_create_home      = optional(bool, false)<br/>      expiredate          = optional(string)<br/>      selinux_user        = optional(string)<br/>      extra               = optional(any, {})<br/>    })))<br/>    groups              = optional(map(list(string)))<br/>    ssh_authorized_keys = optional(list(string), [])<br/>    files = optional(map(object({<br/>      content     = optional(string, "")<br/>      owner       = optional(string, "root:root")<br/>      permissions = optional(string, "0644")<br/>      encoding    = optional(string, "text/plain")<br/>      append      = optional(bool, false)<br/>      defer       = optional(bool, false)<br/>      source_uri  = optional(string)<br/>    })), {})<br/>    systemd_units = optional(list(object({<br/>      name    = string<br/>      type    = optional(string, "service")<br/>      content = string<br/>      enabled = optional(bool, false)<br/>      dropins = optional(map(string), {})<br/>    })), [])<br/>    secrets = optional(list(object({<br/>      name        = string<br/>      destination = string<br/>      source_path = optional(string)<br/>      command     = optional(string)<br/>      owner       = optional(string)<br/>      permissions = optional(string, "0600")<br/>    })), [])<br/>    commands          = optional(any, [])<br/>    boot_commands     = optional(any, [])<br/>    hostname          = optional(string)<br/>    fqdn              = optional(string)<br/>    preserve_hostname = optional(bool, false)<br/>    timezone          = optional(string)<br/>    mounts            = optional(list(list(string)), [])<br/>    swap = optional(object({<br/>      filename = string<br/>      size     = optional(string, "auto")<br/>      maxsize  = optional(string)<br/>    }))<br/>    growpart = optional(object({<br/>      mode                     = optional(string, "auto")<br/>      devices                  = optional(list(string), ["/"])<br/>      ignore_growroot_disabled = optional(bool, false)<br/>    }))<br/>    resize_rootfs = optional(string)<br/>    disk_setup = optional(map(object({<br/>      table_type = optional(string, "mbr")<br/>      layout     = optional(any, false)<br/>      overwrite  = optional(bool, false)<br/>    })), {})<br/>    fs_setup = optional(list(object({<br/>      label      = optional(string)<br/>      filesystem = string<br/>      device     = string<br/>      partition  = optional(string)<br/>      overwrite  = optional(bool, false)<br/>      extra_opts = optional(list(string), [])<br/>    })), [])<br/>    device_aliases = optional(map(string), {})<br/>    ssh = optional(object({<br/>      enabled              = optional(bool, true)<br/>      emit_keys_to_console = optional(bool, true)<br/>    }))<br/>    ssh_genkeytypes = optional(list(string))<br/>    ssh_deletekeys  = optional(bool)<br/>    ca_certs = optional(object({<br/>      trusted         = optional(list(string), [])<br/>      remove_defaults = optional(bool, false)<br/>    }))<br/>    ntp = optional(object({<br/>      enabled    = optional(bool, true)<br/>      ntp_client = optional(string)<br/>      pools      = optional(list(string), [])<br/>      servers    = optional(list(string), [])<br/>    }))<br/>    apt = optional(object({<br/>      preserve_sources_list = optional(bool)<br/>      disable_suites        = optional(list(string), [])<br/>      sources = optional(map(object({<br/>        source    = string<br/>        keyid     = optional(string)<br/>        key       = optional(string)<br/>        keyserver = optional(string)<br/>      })), {})<br/>    }))<br/>    yum_repos = optional(map(object({<br/>      baseurl = optional(string)<br/>      extra   = optional(any, {})<br/>    })), {})<br/>    ansible_pull = optional(list(object({<br/>      url             = string<br/>      playbook_names  = list(string)<br/>      checkout        = optional(string)<br/>      accept_host_key = optional(bool, true)<br/>      full            = optional(bool)<br/>      clean           = optional(bool)<br/>      timeout         = optional(number)<br/>    })), [])<br/>    ansible_install_method = optional(string, "distro")<br/>    power_state = optional(object({<br/>      mode      = string<br/>      delay     = optional(string, "now")<br/>      message   = optional(string)<br/>      timeout   = optional(number, 30)<br/>      condition = optional(string, "true")<br/>    }))<br/>    phone_home = optional(object({<br/>      url   = string<br/>      post  = optional(list(string), ["instance_id", "hostname", "fqdn"])<br/>      tries = optional(number, 10)<br/>    }))<br/>    rsyslog = optional(object({<br/>      configs = optional(list(string), [])<br/>      remotes = optional(map(string), {})<br/>    }))<br/>    artifacts = optional(list(object({<br/>      source       = string<br/>      destination  = string<br/>      owner        = optional(string)<br/>      permissions  = optional(string)<br/>      sha256       = optional(string)<br/>      region       = optional(string)<br/>      endpoint_url = optional(string)<br/>      extract      = optional(bool, false)<br/>      extract_to   = optional(string)<br/>    })), [])<br/>    ansible_playbooks = optional(list(object({<br/>      path       = string<br/>      inventory  = optional(string, "localhost,")<br/>      connection = optional(string, "local")<br/>      extra_vars = optional(map(string), {})<br/>      tags       = optional(list(string), [])<br/>      become     = optional(bool, true)<br/>    })), [])<br/>    ansible_core_install = optional(bool, true)<br/>    execution_steps = optional(list(object({<br/>      command = string<br/>      cwd     = optional(string)<br/>      env     = optional(map(string), {})<br/>    })), [])<br/>  })</pre> | `{}` | no |
| <a name="input_cpu_alarm_high"></a> [cpu\_alarm\_high](#input\_cpu\_alarm\_high) | Triggers the scale-up policy. | <pre>object({<br/>    threshold_percent  = optional(number, 80)<br/>    period_seconds     = optional(number, 300)<br/>    evaluation_periods = optional(number, 2)<br/>  })</pre> | `{}` | no |
| <a name="input_cpu_alarm_low"></a> [cpu\_alarm\_low](#input\_cpu\_alarm\_low) | Triggers the scale-down policy. | <pre>object({<br/>    threshold_percent  = optional(number, 20)<br/>    period_seconds     = optional(number, 300)<br/>    evaluation_periods = optional(number, 2)<br/>  })</pre> | `{}` | no |
| <a name="input_cpu_options"></a> [cpu\_options](#input\_cpu\_options) | n/a | <pre>object({<br/>    core_count            = optional(number)<br/>    threads_per_core      = optional(number)<br/>    amd_sev_snp           = optional(string)<br/>    nested_virtualization = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_credit_specification"></a> [credit\_specification](#input\_credit\_specification) | cpu\_credits: "standard" or "unlimited" - only meaningful for T-class instances. | `string` | `null` | no |
| <a name="input_desired_capacity"></a> [desired\_capacity](#input\_desired\_capacity) | n/a | `number` | `null` | no |
| <a name="input_disable_api_termination"></a> [disable\_api\_termination](#input\_disable\_api\_termination) | n/a | `bool` | `null` | no |
| <a name="input_ebs_optimized"></a> [ebs\_optimized](#input\_ebs\_optimized) | n/a | `bool` | `null` | no |
| <a name="input_enable_monitoring"></a> [enable\_monitoring](#input\_enable\_monitoring) | Detailed (1-minute) CloudWatch monitoring. | `bool` | `true` | no |
| <a name="input_force_delete"></a> [force\_delete](#input\_force\_delete) | n/a | `bool` | `false` | no |
| <a name="input_health_check_grace_period"></a> [health\_check\_grace\_period](#input\_health\_check\_grace\_period) | n/a | `number` | `null` | no |
| <a name="input_health_check_type"></a> [health\_check\_type](#input\_health\_check\_type) | n/a | `string` | `"EC2"` | no |
| <a name="input_iam_instance_profile_name"></a> [iam\_instance\_profile\_name](#input\_iam\_instance\_profile\_name) | Name of an existing IAM instance profile. No instance profile attached if null. | `string` | `null` | no |
| <a name="input_identity"></a> [identity](#input\_identity) | Instance identity strategy. mode = "none" (default) changes nothing - use cloudinit\_config.hostname/fqdn directly as before. "aws\_native" configures the launch template's private DNS hostname (AWS EC2/VPC feature, no CloudInit involved). "static" is equivalent to "none" for a single fixed hostname/fqdn, kept separate so identity.mode is the one place that documents which authority owns naming. "custom\_runtime" generates a per-instance hostname at boot, via a bootstrap script querying IMDSv2 - the only mode safe for a scaling group that needs its own naming convention instead of aws\_native. | <pre>object({<br/>    mode = optional(string, "none") # "none" | "aws_native" | "static" | "custom_runtime"<br/><br/>    aws_native = optional(object({<br/>      hostname_type                        = string # "ip-name" | "resource-name"<br/>      enable_resource_name_dns_a_record    = optional(bool, false)<br/>      enable_resource_name_dns_aaaa_record = optional(bool, false)<br/>    }))<br/><br/>    static = optional(object({<br/>      hostname = string<br/>      fqdn     = optional(string)<br/>    }))<br/><br/>    custom_runtime = optional(object({<br/>      hostname_template = string                    # e.g. "{service}-{environment}-{instance_id}"<br/>      domain            = optional(string)          # for FQDN construction - local /etc/hosts entry only, never real DNS registration<br/>      variables         = optional(map(string), {}) # static substitutions, known at plan time: service, environment, role, ...<br/>    }))<br/>  })</pre> | `{}` | no |
| <a name="input_instance_initiated_shutdown_behavior"></a> [instance\_initiated\_shutdown\_behavior](#input\_instance\_initiated\_shutdown\_behavior) | "stop" or "terminate". | `string` | `null` | no |
| <a name="input_instance_refresh"></a> [instance\_refresh](#input\_instance\_refresh) | n/a | <pre>object({<br/>    strategy = string<br/>    preferences = optional(object({<br/>      min_healthy_percentage = optional(number)<br/>      instance_warmup        = optional(number)<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Default instance type. Ignored per-override if mixed\_instances\_policy sets its own overrides. | `string` | n/a | yes |
| <a name="input_instance_warmup"></a> [instance\_warmup](#input\_instance\_warmup) | Shorthand: sets instance\_refresh.preferences.instance\_warmup without requiring the full instance\_refresh block. Ignored if instance\_refresh.preferences.instance\_warmup is set explicitly. | `number` | `null` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | n/a | `string` | `null` | no |
| <a name="input_launch_template_version"></a> [launch\_template\_version](#input\_launch\_template\_version) | Version the ASG launches from. "$Latest" tracks every change automatically. | `string` | `"$Latest"` | no |
| <a name="input_license_specifications"></a> [license\_specifications](#input\_license\_specifications) | n/a | <pre>list(object({<br/>    license_configuration_arn = string<br/>  }))</pre> | `[]` | no |
| <a name="input_lifecycle_hooks"></a> [lifecycle\_hooks](#input\_lifecycle\_hooks) | ASG lifecycle hooks. Each entry creates one aws\_autoscaling\_lifecycle\_hook. | <pre>list(object({<br/>    name                    = string<br/>    lifecycle_transition    = optional(string, "autoscaling:EC2_INSTANCE_LAUNCHING")<br/>    role_arn                = optional(string)<br/>    notification_target_arn = optional(string)<br/>    notification_metadata   = optional(string)<br/>    heartbeat_timeout       = optional(number, 300)<br/>    default_result          = optional(string, "CONTINUE")<br/>  }))</pre> | `[]` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | n/a | `number` | n/a | yes |
| <a name="input_metadata_options"></a> [metadata\_options](#input\_metadata\_options) | Instance metadata service options. Defaults enforce IMDSv2. | <pre>object({<br/>    http_endpoint               = optional(string, "enabled")<br/>    http_tokens                 = optional(string, "required")<br/>    http_put_response_hop_limit = optional(number, 2)<br/>  })</pre> | `{}` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | n/a | `number` | n/a | yes |
| <a name="input_mixed_instances_policy"></a> [mixed\_instances\_policy](#input\_mixed\_instances\_policy) | On-demand/spot mix. Null = plain single-instance-type ASG using instance\_type/ami\_id directly. | <pre>object({<br/>    on_demand_base_capacity                  = optional(number)<br/>    on_demand_percentage_above_base_capacity = optional(number)<br/>    spot_allocation_strategy                 = optional(string)<br/>    overrides = optional(list(object({<br/>      instance_type = string<br/>    })), [])<br/>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name for the launch template, ASG, and tagger name. Caller's responsibility to keep unique. | `string` | n/a | yes |
| <a name="input_network_interfaces"></a> [network\_interfaces](#input\_network\_interfaces) | Advanced override: full control over the launch template's network\_interfaces blocks (e.g. multiple ENIs). When set, vpc\_security\_group\_ids and associate\_public\_ip\_address are ignored - put security\_groups/associate\_public\_ip\_address inside each entry instead. Leave empty (default) for the common case of one ENI built from vpc\_security\_group\_ids/associate\_public\_ip\_address below. | <pre>list(object({<br/>    associate_public_ip_address = optional(bool)<br/>    delete_on_termination       = optional(bool)<br/>    description                 = optional(string)<br/>    device_index                = optional(number)<br/>    security_groups             = optional(list(string))<br/>    subnet_id                   = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_placement"></a> [placement](#input\_placement) | n/a | <pre>object({<br/>    affinity                = optional(string)<br/>    availability_zone       = optional(string)<br/>    group_name              = optional(string)<br/>    host_id                 = optional(string)<br/>    host_resource_group_arn = optional(string)<br/>    spread_domain           = optional(string)<br/>    tenancy                 = optional(string)<br/>    partition_number        = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_protect_from_scale_in"></a> [protect\_from\_scale\_in](#input\_protect\_from\_scale\_in) | Required true for ECS managed\_termination\_protection to work when this ASG backs an ECS capacity provider. | `bool` | `false` | no |
| <a name="input_scale_down_policy"></a> [scale\_down\_policy](#input\_scale\_down\_policy) | n/a | <pre>object({<br/>    scaling_adjustment = optional(number, -1)<br/>    adjustment_type    = optional(string, "ChangeInCapacity")<br/>    cooldown_seconds   = optional(number, 300)<br/>  })</pre> | `{}` | no |
| <a name="input_scale_up_policy"></a> [scale\_up\_policy](#input\_scale\_up\_policy) | n/a | <pre>object({<br/>    scaling_adjustment = optional(number, 1)<br/>    adjustment_type    = optional(string, "ChangeInCapacity")<br/>    cooldown_seconds   = optional(number, 300)<br/>  })</pre> | `{}` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | n/a | `list(string)` | n/a | yes |
| <a name="input_suspended_processes"></a> [suspended\_processes](#input\_suspended\_processes) | n/a | `list(string)` | `[]` | no |
| <a name="input_tag_specifications_resource_types"></a> [tag\_specifications\_resource\_types](#input\_tag\_specifications\_resource\_types) | Which launch-template tag\_specifications blocks to emit, all carrying the same tagger tags. | `list(string)` | <pre>[<br/>  "instance",<br/>  "volume",<br/>  "network-interface"<br/>]</pre> | no |
| <a name="input_tagger_additional_services"></a> [tagger\_additional\_services](#input\_tagger\_additional\_services) | Extra terraform-null-tagger `service` data per taggable resource, keyed by the same key as local.taggable (e.g. "subnet-public-a"). Merged on top of what this module computes automatically - lets a caller tag something this module doesn't know about, without waiting for a new module release. | `any` | `{}` | no |
| <a name="input_tagger_context"></a> [tagger\_context](#input\_tagger\_context) | module.tagger.context from the root stack's base terraform-null-tagger call. | `any` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Custom tags for the resource(s). | `map(string)` | `{}` | no |
| <a name="input_termination_policies"></a> [termination\_policies](#input\_termination\_policies) | n/a | `list(string)` | `[]` | no |
| <a name="input_topology_vpc_id"></a> [topology\_vpc\_id](#input\_topology\_vpc\_id) | VPC id, for the topology\_fragment diagram only - used solely to nest this ASG under its VPC when subnet\_ids spans more than one subnet. The module has no other reason to need a vpc\_id, so this stays optional and unused by every actual resource here. Omit it and the ASG simply floats at the top level of the merged diagram instead. | `string` | `null` | no |
| <a name="input_update_default_version"></a> [update\_default\_version](#input\_update\_default\_version) | Set the newest launch template version as the default on every change. | `bool` | `true` | no |
| <a name="input_use_tagger"></a> [use\_tagger](#input\_use\_tagger) | Compute and apply standardized tags via terraform-null-tagger. When false, use var.tags as-is instead. | `bool` | `true` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | Ignored if network\_interfaces is set (see that variable's description). | `list(string)` | `[]` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_autoscaling_group_arn"></a> [autoscaling\_group\_arn](#output\_autoscaling\_group\_arn) | n/a |
| <a name="output_autoscaling_group_name"></a> [autoscaling\_group\_name](#output\_autoscaling\_group\_name) | n/a |
| <a name="output_cloudinit_required_permissions"></a> [cloudinit\_required\_permissions](#output\_cloudinit\_required\_permissions) | IAM permissions required by cloud-init artifacts (S3, etc.). Attach to your instance role. Null values mean that provider's scheme is not used. |
| <a name="output_launch_template_id"></a> [launch\_template\_id](#output\_launch\_template\_id) | n/a |
| <a name="output_launch_template_latest_version"></a> [launch\_template\_latest\_version](#output\_launch\_template\_latest\_version) | n/a |
| <a name="output_topology_fragment"></a> [topology\_fragment](#output\_topology\_fragment) | Network topology fragment for composition with sibling modules via provider::netutils::mermaid\_merge(). See terraform-provider-netutils's docs/topology-fragment-spec.md. |



## License

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

```text
The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files, to deal in the Software
without restriction.

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.

Source: https://opensource.org/licenses/MIT
```


See [LICENSE](LICENSE) for full details.


## Authors

- Rafał Masiarek | [website](https://masiarek.pl) | [email](mailto:rafal@masiarek.pl) | [github](https://github.com/rafalmasiarek)




<!-- references -->

[repo_link]: https://github.com/rafalmasiarek/terraform-aws-ec2-autoscale-group

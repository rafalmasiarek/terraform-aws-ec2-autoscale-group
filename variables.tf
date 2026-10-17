variable "name" {
  description = "Name for the launch template, ASG, and tagger name. Caller's responsibility to keep unique."
  type        = string
}

variable "ami_id" {
  description = "AMI to launch. No default, no internal data source - resolve it in the caller's own stack."
  type        = string
}

variable "instance_type" {
  description = "Default instance type. Ignored per-override if mixed_instances_policy sets its own overrides."
  type        = string
}

variable "key_name" {
  type    = string
  default = null
}

variable "iam_instance_profile_name" {
  description = "Name of an existing IAM instance profile. No instance profile attached if null."
  type        = string
  default     = null
}

variable "cloudinit_config" {
  description = "Typed pass-through to terraform-null-cloudinit. Every field mirrors that module's variables.tf exactly - see https://github.com/rafalmasiarek/terraform-null-cloudinit for full documentation."
  type = object({
    cloud_config           = optional(any)
    shell_scripts          = optional(list(string), [])
    cloudinit_parts        = optional(list(object({
      content_type = string
      content      = string
      filename     = optional(string)
      merge_type   = optional(string)
    })), [])
    gzip                   = optional(bool, false)
    max_bytes              = optional(number, 16384)
    scripts                = optional(object({
      per_boot     = optional(list(string), [])
      per_instance = optional(list(string), [])
      per_once     = optional(list(string), [])
      boothook     = optional(list(string), [])
    }), {})
    packages               = optional(object({
      install            = optional(any, [])
      update             = optional(bool, false)
      upgrade            = optional(bool, false)
      reboot_if_required = optional(bool, false)
    }))
    users                  = optional(list(object({
      name                = string
      gecos               = optional(string)
      groups              = optional(list(string))
      shell               = optional(string)
      sudo                = optional(string)
      lock_passwd         = optional(bool, true)
      ssh_authorized_keys = optional(list(string))
      ssh_import_id       = optional(list(string))
      passwd              = optional(string)
      hashed_passwd       = optional(string)
      plain_text_passwd   = optional(string)
      system              = optional(bool, false)
      uid                 = optional(number)
      primary_group       = optional(string)
      homedir             = optional(string)
      no_create_home      = optional(bool, false)
      expiredate          = optional(string)
      selinux_user        = optional(string)
      extra               = optional(any, {})
    })))
    groups                 = optional(map(list(string)))
    ssh_authorized_keys    = optional(list(string), [])
    files                  = optional(map(object({
      content     = optional(string, "")
      owner       = optional(string, "root:root")
      permissions = optional(string, "0644")
      encoding    = optional(string, "text/plain")
      append      = optional(bool, false)
      defer       = optional(bool, false)
      source_uri  = optional(string)
    })), {})
    systemd_units          = optional(list(object({
      name    = string
      type    = optional(string, "service")
      content = string
      enabled = optional(bool, false)
      dropins = optional(map(string), {})
    })), [])
    secrets                = optional(list(object({
      name        = string
      destination = string
      source_path = optional(string)
      command     = optional(string)
      owner       = optional(string)
      permissions = optional(string, "0600")
    })), [])
    commands               = optional(any, [])
    boot_commands          = optional(any, [])
    hostname               = optional(string)
    fqdn                   = optional(string)
    preserve_hostname      = optional(bool, false)
    timezone               = optional(string)
    mounts                 = optional(list(list(string)), [])
    swap                   = optional(object({
      filename = string
      size     = optional(string, "auto")
      maxsize  = optional(string)
    }))
    growpart               = optional(object({
      mode                     = optional(string, "auto")
      devices                  = optional(list(string), ["/"])
      ignore_growroot_disabled = optional(bool, false)
    }))
    resize_rootfs          = optional(string)
    disk_setup             = optional(map(object({
      table_type = optional(string, "mbr")
      layout     = optional(any, false)
      overwrite  = optional(bool, false)
    })), {})
    fs_setup               = optional(list(object({
      label      = optional(string)
      filesystem = string
      device     = string
      partition  = optional(string)
      overwrite  = optional(bool, false)
      extra_opts = optional(list(string), [])
    })), [])
    device_aliases         = optional(map(string), {})
    ssh                    = optional(object({
      enabled              = optional(bool, true)
      emit_keys_to_console = optional(bool, true)
    }))
    ssh_genkeytypes        = optional(list(string))
    ssh_deletekeys         = optional(bool)
    ca_certs               = optional(object({
      trusted         = optional(list(string), [])
      remove_defaults = optional(bool, false)
    }))
    ntp                    = optional(object({
      enabled    = optional(bool, true)
      ntp_client = optional(string)
      pools      = optional(list(string), [])
      servers    = optional(list(string), [])
    }))
    apt                    = optional(object({
      preserve_sources_list = optional(bool)
      disable_suites        = optional(list(string), [])
      sources = optional(map(object({
        source    = string
        keyid     = optional(string)
        key       = optional(string)
        keyserver = optional(string)
      })), {})
    }))
    yum_repos              = optional(map(object({
      baseurl = optional(string)
      extra   = optional(any, {})
    })), {})
    ansible_pull           = optional(list(object({
      url             = string
      playbook_names  = list(string)
      checkout        = optional(string)
      accept_host_key = optional(bool, true)
      full            = optional(bool)
      clean           = optional(bool)
      timeout         = optional(number)
    })), [])
    ansible_install_method = optional(string, "distro")
    power_state            = optional(object({
      mode      = string
      delay     = optional(string, "now")
      message   = optional(string)
      timeout   = optional(number, 30)
      condition = optional(string, "true")
    }))
    phone_home             = optional(object({
      url   = string
      post  = optional(list(string), ["instance_id", "hostname", "fqdn"])
      tries = optional(number, 10)
    }))
    rsyslog                = optional(object({
      configs = optional(list(string), [])
      remotes = optional(map(string), {})
    }))
    artifacts              = optional(list(object({
      source       = string
      destination  = string
      owner        = optional(string)
      permissions  = optional(string)
      sha256       = optional(string)
      region       = optional(string)
      endpoint_url = optional(string)
      extract      = optional(bool, false)
      extract_to   = optional(string)
    })), [])
    ansible_playbooks      = optional(list(object({
      path       = string
      inventory  = optional(string, "localhost,")
      connection = optional(string, "local")
      extra_vars = optional(map(string), {})
      tags       = optional(list(string), [])
      become     = optional(bool, true)
    })), [])
    ansible_core_install   = optional(bool, true)
    execution_steps        = optional(list(object({
      command = string
      cwd     = optional(string)
      env     = optional(map(string), {})
    })), [])
  })
  default = {}
}

variable "ebs_optimized" {
  type    = bool
  default = null
}

variable "disable_api_termination" {
  type    = bool
  default = null
}

variable "instance_initiated_shutdown_behavior" {
  description = "\"stop\" or \"terminate\"."
  type        = string
  default     = null
}

variable "update_default_version" {
  description = "Set the newest launch template version as the default on every change."
  type        = bool
  default     = true
}

variable "launch_template_version" {
  description = "Version the ASG launches from. \"$Latest\" tracks every change automatically."
  type        = string
  default     = "$Latest"
}

variable "enable_monitoring" {
  description = "Detailed (1-minute) CloudWatch monitoring."
  type        = bool
  default     = true
}

variable "metadata_options" {
  description = "Instance metadata service options. Defaults enforce IMDSv2."
  type = object({
    http_endpoint               = optional(string, "enabled")
    http_tokens                 = optional(string, "required")
    http_put_response_hop_limit = optional(number, 2)
  })
  default = {}
}

variable "block_device_mappings" {
  type = list(object({
    device_name = string
    ebs = optional(object({
      delete_on_termination = optional(bool)
      encrypted             = optional(bool)
      iops                  = optional(number)
      kms_key_id            = optional(string)
      snapshot_id           = optional(string)
      throughput            = optional(number)
      volume_size           = optional(number)
      volume_type           = optional(string)
    }))
  }))
  default = []
}

variable "cpu_options" {
  type = object({
    core_count            = optional(number)
    threads_per_core      = optional(number)
    amd_sev_snp           = optional(string)
    nested_virtualization = optional(bool)
  })
  default = null
}

variable "credit_specification" {
  description = "cpu_credits: \"standard\" or \"unlimited\" - only meaningful for T-class instances."
  type        = string
  default     = null
}

variable "placement" {
  type = object({
    affinity                = optional(string)
    availability_zone       = optional(string)
    group_name              = optional(string)
    host_id                 = optional(string)
    host_resource_group_arn = optional(string)
    spread_domain           = optional(string)
    tenancy                 = optional(string)
    partition_number        = optional(number)
  })
  default = null
}

variable "license_specifications" {
  type = list(object({
    license_configuration_arn = string
  }))
  default = []
}

variable "network_interfaces" {
  description = "Advanced override: full control over the launch template's network_interfaces blocks (e.g. multiple ENIs). When set, vpc_security_group_ids and associate_public_ip_address are ignored - put security_groups/associate_public_ip_address inside each entry instead. Leave empty (default) for the common case of one ENI built from vpc_security_group_ids/associate_public_ip_address below."
  type = list(object({
    associate_public_ip_address = optional(bool)
    delete_on_termination       = optional(bool)
    description                 = optional(string)
    device_index                = optional(number)
    security_groups             = optional(list(string))
    subnet_id                   = optional(string)
  }))
  default = []
}

variable "associate_public_ip_address" {
  description = "Assign a public IP to instances launched from this template - needed to reach the internet (pull images, etc.) without a NAT Gateway when running in a public subnet. Ignored if network_interfaces is set."
  type        = bool
  default     = false
}

variable "tag_specifications_resource_types" {
  description = "Which launch-template tag_specifications blocks to emit, all carrying the same tagger tags."
  type        = list(string)
  default     = ["instance", "volume", "network-interface"]
}

# --- Auto Scaling Group ---

variable "subnet_ids" {
  type = list(string)
}

variable "vpc_security_group_ids" {
  description = "Ignored if network_interfaces is set (see that variable's description)."
  type        = list(string)
  default     = []
}

variable "min_size" {
  type        = number
  validation {
    condition     = var.min_size >= 0
    error_message = "min_size must be >= 0."
  }
}

variable "max_size" {
  type        = number
  validation {
    condition     = var.max_size >= 1
    error_message = "max_size must be >= 1."
  }
}

variable "desired_capacity" {
  type    = number
  default = null
}

variable "health_check_type" {
  type    = string
  default = "EC2"
}

variable "health_check_grace_period" {
  type    = number
  default = null
}

variable "protect_from_scale_in" {
  description = "Required true for ECS managed_termination_protection to work when this ASG backs an ECS capacity provider."
  type        = bool
  default     = false
}

variable "force_delete" {
  type    = bool
  default = false
}

variable "termination_policies" {
  type    = list(string)
  default = []
}

variable "suspended_processes" {
  type    = list(string)
  default = []
}

variable "mixed_instances_policy" {
  description = "On-demand/spot mix. Null = plain single-instance-type ASG using instance_type/ami_id directly."
  type = object({
    on_demand_base_capacity                  = optional(number)
    on_demand_percentage_above_base_capacity = optional(number)
    spot_allocation_strategy                 = optional(string)
    overrides = optional(list(object({
      instance_type = string
    })), [])
  })
  default = null
}

variable "instance_refresh" {
  type = object({
    strategy = string
    preferences = optional(object({
      min_healthy_percentage = optional(number)
      instance_warmup        = optional(number)
    }))
  })
  default = null
}

variable "instance_warmup" {
  description = "Shorthand: sets instance_refresh.preferences.instance_warmup without requiring the full instance_refresh block. Ignored if instance_refresh.preferences.instance_warmup is set explicitly."
  type        = number
  default     = null
}

variable "spot_instance_rebalance_requirements" {
  description = "\"terminate\" to terminate Spot instances when rebalancing notifications are received. Only meaningful with mixed_instances_policy that includes Spot."
  type        = string
  default     = null
}

variable "lifecycle_hooks" {
  description = "ASG lifecycle hooks. Each entry creates one aws_autoscaling_lifecycle_hook."
  type = list(object({
    name                  = string
    lifecycle_transition  = optional(string, "autoscaling:EC2_INSTANCE_LAUNCHING")
    role_arn              = optional(string)
    notification_target_arn = optional(string)
    notification_metadata = optional(string)
    heartbeat_timeout     = optional(number, 300)
    default_result        = optional(string, "CONTINUE")
  }))
  default = []

  validation {
    condition     = alltrue([for h in var.lifecycle_hooks : contains(["autoscaling:EC2_INSTANCE_LAUNCHING", "autoscaling:EC2_INSTANCE_LAUNCH_COMPLETE", "autoscaling:EC2_INSTANCE_TERMINATING", "autoscaling:EC2_INSTANCE_TERMINATE", "autoscaling:TEST_INSTANCE"], h.lifecycle_transition)])
    error_message = "lifecycle_hooks[].lifecycle_transition must be a valid ASG lifecycle transition (e.g. autoscaling:EC2_INSTANCE_LAUNCHING)."
  }
}

variable "autoscaling_group_tags" {
  description = "Extra ASG tags on top of the tagger's own - merged, tagger wins on conflict."
  type        = map(string)
  default     = {}
}

# --- CPU-based scaling (opt-in) ---

variable "autoscaling_policies_enabled" {
  description = "Create CPU-based scale-up/scale-down policies and CloudWatch alarms for this ASG. Unrelated to ECS capacity-provider managed scaling - this is plain EC2-metric-based autoscaling, independent of whatever consumes the ASG."
  type        = bool
  default     = false
}

variable "scale_up_policy" {
  type = object({
    scaling_adjustment = optional(number, 1)
    adjustment_type    = optional(string, "ChangeInCapacity")
    cooldown_seconds   = optional(number, 300)
  })
  default = {}
}

variable "scale_down_policy" {
  type = object({
    scaling_adjustment = optional(number, -1)
    adjustment_type    = optional(string, "ChangeInCapacity")
    cooldown_seconds   = optional(number, 300)
  })
  default = {}
}

variable "cpu_alarm_high" {
  description = "Triggers the scale-up policy."
  type = object({
    threshold_percent  = optional(number, 80)
    period_seconds     = optional(number, 300)
    evaluation_periods = optional(number, 2)
  })
  default = {}
}

variable "cpu_alarm_low" {
  description = "Triggers the scale-down policy."
  type = object({
    threshold_percent  = optional(number, 20)
    period_seconds     = optional(number, 300)
    evaluation_periods = optional(number, 2)
  })
  default = {}
}

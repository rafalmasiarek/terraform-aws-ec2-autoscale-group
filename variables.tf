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
  description = "Wildcard passthrough to every input of terraform-null-cloudinit (cloud_config, packages, users, files, mounts, ansible_pull, artifacts, ansible_playbooks, ...) - see that module's variables.tf for the full field set. This module never needs a new variable when that one gains a new helper; only this module's own main.tf gains one new try() line."
  type        = any
  default     = {}
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
  type = number
}

variable "max_size" {
  type = number
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
    }))
  })
  default = null
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

locals {
  taggable = {
    this = {
      name = var.name
      service = {
        autoscaling_group = {
          min_size = var.min_size
          max_size = var.max_size
        }
      }
      attributes = []
      created_at = null
      extra_tags = {}
    }
  }

  # Always go through network_interfaces, never the launch template's flat
  # vpc_security_group_ids - that combination has a long-standing provider
  # quirk where associate_public_ip_address doesn't reliably apply
  # (terraform-provider-aws#4570). One default ENI built from
  # vpc_security_group_ids/associate_public_ip_address covers the common
  # case; var.network_interfaces overrides it entirely for advanced needs.
  default_network_interfaces = [{
    device_index                = 0
    associate_public_ip_address = var.associate_public_ip_address
    delete_on_termination       = true
    description                 = null
    security_groups             = var.vpc_security_group_ids
    subnet_id                   = null
  }]

  network_interfaces = length(var.network_interfaces) > 0 ? var.network_interfaces : local.default_network_interfaces
}

module "cloudinit" {
  source = "rafalmasiarek/cloudinit/null"

  cloud_config           = try(var.cloudinit_config.cloud_config, null)
  shell_scripts          = try(var.cloudinit_config.shell_scripts, [])
  cloudinit_parts        = try(var.cloudinit_config.cloudinit_parts, [])
  gzip                   = try(var.cloudinit_config.gzip, false)
  max_bytes              = try(var.cloudinit_config.max_bytes, 16384)
  scripts                = try(var.cloudinit_config.scripts, {})
  packages               = try(var.cloudinit_config.packages, null)
  users                  = try(var.cloudinit_config.users, null)
  groups                 = try(var.cloudinit_config.groups, null)
  ssh_authorized_keys    = try(var.cloudinit_config.ssh_authorized_keys, {})
  files                  = try(var.cloudinit_config.files, {})
  commands               = try(var.cloudinit_config.commands, [])
  boot_commands          = try(var.cloudinit_config.boot_commands, [])
  hostname               = try(var.cloudinit_config.hostname, null)
  fqdn                   = try(var.cloudinit_config.fqdn, null)
  preserve_hostname      = try(var.cloudinit_config.preserve_hostname, false)
  timezone               = try(var.cloudinit_config.timezone, null)
  mounts                 = try(var.cloudinit_config.mounts, [])
  swap                   = try(var.cloudinit_config.swap, null)
  growpart               = try(var.cloudinit_config.growpart, null)
  resize_rootfs          = try(var.cloudinit_config.resize_rootfs, null)
  disk_setup             = try(var.cloudinit_config.disk_setup, {})
  fs_setup               = try(var.cloudinit_config.fs_setup, [])
  device_aliases         = try(var.cloudinit_config.device_aliases, {})
  ssh                    = try(var.cloudinit_config.ssh, null)
  ssh_genkeytypes        = try(var.cloudinit_config.ssh_genkeytypes, null)
  ssh_deletekeys         = try(var.cloudinit_config.ssh_deletekeys, null)
  ca_certs               = try(var.cloudinit_config.ca_certs, null)
  ntp                    = try(var.cloudinit_config.ntp, null)
  apt                    = try(var.cloudinit_config.apt, null)
  yum_repos              = try(var.cloudinit_config.yum_repos, {})
  ansible_pull           = try(var.cloudinit_config.ansible_pull, [])
  ansible_install_method = try(var.cloudinit_config.ansible_install_method, "distro")
  power_state            = try(var.cloudinit_config.power_state, null)
  phone_home             = try(var.cloudinit_config.phone_home, null)
  rsyslog                = try(var.cloudinit_config.rsyslog, null)
  artifacts              = try(var.cloudinit_config.artifacts, [])
  ansible_playbooks      = try(var.cloudinit_config.ansible_playbooks, [])
  ansible_core_install   = try(var.cloudinit_config.ansible_core_install, true)
  execution_steps        = try(var.cloudinit_config.execution_steps, [])
}

resource "aws_launch_template" "this" {
  name = var.name

  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  ebs_optimized = var.ebs_optimized
  user_data     = module.cloudinit.rendered

  disable_api_termination              = var.disable_api_termination
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  update_default_version               = var.update_default_version

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile_name != null ? [var.iam_instance_profile_name] : []
    content {
      name = iam_instance_profile.value
    }
  }

  monitoring {
    enabled = var.enable_monitoring
  }

  metadata_options {
    http_endpoint               = var.metadata_options.http_endpoint
    http_tokens                 = var.metadata_options.http_tokens
    http_put_response_hop_limit = var.metadata_options.http_put_response_hop_limit
  }

  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings
    content {
      device_name = block_device_mappings.value.device_name

      dynamic "ebs" {
        for_each = block_device_mappings.value.ebs != null ? [block_device_mappings.value.ebs] : []
        content {
          delete_on_termination = try(ebs.value.delete_on_termination, null)
          encrypted             = try(ebs.value.encrypted, null)
          iops                  = try(ebs.value.iops, null)
          kms_key_id            = try(ebs.value.kms_key_id, null)
          snapshot_id           = try(ebs.value.snapshot_id, null)
          throughput            = try(ebs.value.throughput, null)
          volume_size           = try(ebs.value.volume_size, null)
          volume_type           = try(ebs.value.volume_type, null)
        }
      }
    }
  }

  dynamic "cpu_options" {
    for_each = var.cpu_options != null ? [var.cpu_options] : []
    content {
      core_count            = try(cpu_options.value.core_count, null)
      threads_per_core      = try(cpu_options.value.threads_per_core, null)
      amd_sev_snp           = try(cpu_options.value.amd_sev_snp, null)
      nested_virtualization = try(cpu_options.value.nested_virtualization, null)
    }
  }

  dynamic "credit_specification" {
    for_each = var.credit_specification != null ? [var.credit_specification] : []
    content {
      cpu_credits = credit_specification.value
    }
  }

  dynamic "placement" {
    for_each = var.placement != null ? [var.placement] : []
    content {
      affinity                = try(placement.value.affinity, null)
      availability_zone       = try(placement.value.availability_zone, null)
      group_name              = try(placement.value.group_name, null)
      host_id                 = try(placement.value.host_id, null)
      host_resource_group_arn = try(placement.value.host_resource_group_arn, null)
      spread_domain           = try(placement.value.spread_domain, null)
      tenancy                 = try(placement.value.tenancy, null)
      partition_number        = try(placement.value.partition_number, null)
    }
  }

  dynamic "license_specification" {
    for_each = var.license_specifications
    content {
      license_configuration_arn = license_specification.value.license_configuration_arn
    }
  }

  dynamic "network_interfaces" {
    for_each = local.network_interfaces
    content {
      associate_public_ip_address = try(network_interfaces.value.associate_public_ip_address, null)
      delete_on_termination       = try(network_interfaces.value.delete_on_termination, null)
      description                 = try(network_interfaces.value.description, null)
      device_index                = try(network_interfaces.value.device_index, null)
      security_groups             = try(network_interfaces.value.security_groups, null)
      subnet_id                   = try(network_interfaces.value.subnet_id, null)
    }
  }

  dynamic "tag_specifications" {
    for_each = var.tag_specifications_resource_types
    content {
      resource_type = tag_specifications.value
      tags          = local.tagger_tags["this"]
    }
  }

  tags = local.tagger_tags["this"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  name = var.name

  vpc_zone_identifier = var.subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity

  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period

  protect_from_scale_in = var.protect_from_scale_in
  force_delete          = var.force_delete
  termination_policies  = var.termination_policies
  suspended_processes   = var.suspended_processes

  dynamic "launch_template" {
    for_each = var.mixed_instances_policy == null ? [1] : []
    content {
      id      = aws_launch_template.this.id
      version = var.launch_template_version
    }
  }

  dynamic "mixed_instances_policy" {
    for_each = var.mixed_instances_policy != null ? [var.mixed_instances_policy] : []
    content {
      launch_template {
        launch_template_specification {
          launch_template_id = aws_launch_template.this.id
          version            = var.launch_template_version
        }

        dynamic "override" {
          for_each = mixed_instances_policy.value.overrides
          content {
            instance_type = override.value.instance_type
          }
        }
      }

      instances_distribution {
        on_demand_base_capacity                  = try(mixed_instances_policy.value.on_demand_base_capacity, null)
        on_demand_percentage_above_base_capacity = try(mixed_instances_policy.value.on_demand_percentage_above_base_capacity, null)
        spot_allocation_strategy                 = try(mixed_instances_policy.value.spot_allocation_strategy, null)
      }
    }
  }

  dynamic "instance_refresh" {
    for_each = var.instance_refresh != null ? [var.instance_refresh] : []
    content {
      strategy = instance_refresh.value.strategy

      dynamic "preferences" {
        for_each = instance_refresh.value.preferences != null ? [instance_refresh.value.preferences] : []
        content {
          min_healthy_percentage = try(preferences.value.min_healthy_percentage, null)
        }
      }
    }
  }

  dynamic "tag" {
    for_each = merge(local.tagger_tags["this"], var.autoscaling_group_tags)
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

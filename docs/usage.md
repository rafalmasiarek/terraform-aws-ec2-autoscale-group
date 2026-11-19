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

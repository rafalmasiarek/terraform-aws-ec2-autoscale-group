resource "aws_autoscaling_policy" "scale_up" {
  count = var.autoscaling_policies_enabled ? 1 : 0

  name                   = "${var.name}-scale-up"
  autoscaling_group_name = aws_autoscaling_group.this.name
  scaling_adjustment     = var.scale_up_policy.scaling_adjustment
  adjustment_type        = var.scale_up_policy.adjustment_type
  cooldown               = var.scale_up_policy.cooldown_seconds
}

resource "aws_autoscaling_policy" "scale_down" {
  count = var.autoscaling_policies_enabled ? 1 : 0

  name                   = "${var.name}-scale-down"
  autoscaling_group_name = aws_autoscaling_group.this.name
  scaling_adjustment     = var.scale_down_policy.scaling_adjustment
  adjustment_type        = var.scale_down_policy.adjustment_type
  cooldown               = var.scale_down_policy.cooldown_seconds
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count = var.autoscaling_policies_enabled ? 1 : 0

  alarm_name          = "${var.name}-cpu-utilization-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.cpu_alarm_high.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.cpu_alarm_high.period_seconds
  statistic           = "Average"
  threshold           = var.cpu_alarm_high.threshold_percent
  alarm_description   = "Scale up ${var.name} when CPU >= ${var.cpu_alarm_high.threshold_percent}% for ${var.cpu_alarm_high.period_seconds}s x ${var.cpu_alarm_high.evaluation_periods}"
  alarm_actions       = [aws_autoscaling_policy.scale_up[0].arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }

  tags = local.tagger_tags["this"]
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  count = var.autoscaling_policies_enabled ? 1 : 0

  alarm_name          = "${var.name}-cpu-utilization-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.cpu_alarm_low.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.cpu_alarm_low.period_seconds
  statistic           = "Average"
  threshold           = var.cpu_alarm_low.threshold_percent
  alarm_description   = "Scale down ${var.name} when CPU <= ${var.cpu_alarm_low.threshold_percent}% for ${var.cpu_alarm_low.period_seconds}s x ${var.cpu_alarm_low.evaluation_periods}"
  alarm_actions       = [aws_autoscaling_policy.scale_down[0].arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }

  tags = local.tagger_tags["this"]
}

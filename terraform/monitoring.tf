resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "phishing-detector-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "EC2 CPU Utilization"
          region = "eu-north-1"
          period = 300
          stat   = "Average"

          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.app[0].id],
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.app[1].id]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "ALB Request Count"
          region = "eu-north-1"
          period = 60
          stat   = "Sum"

          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.app.arn_suffix]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "HTTP 5xx Errors"
          region = "eu-north-1"
          period = 60
          stat   = "Sum"

          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.app.arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", aws_lb.app.arn_suffix]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "Healthy EC2 Targets"
          region = "eu-north-1"
          period = 60
          stat   = "Minimum"

          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount",
              "LoadBalancer", aws_lb.app.arn_suffix,
            "TargetGroup", aws_lb_target_group.app.arn_suffix]
          ]
        }
      }
    ]
  })
}

# High CPU alarm for each EC2 instance
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = 2

  alarm_name        = "phishing-high-cpu-${count.index + 1}"
  alarm_description = "EC2 CPU above 80 percent"

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  dimensions = {
    InstanceId = aws_instance.app[count.index].id
  }

  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  treat_missing_data = "missing"
}

# Alarm when fewer than two targets are healthy
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name        = "phishing-unhealthy-targets"
  alarm_description = "Fewer than two healthy EC2 targets"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HealthyHostCount"

  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }

  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 2
  comparison_operator = "LessThanThreshold"

  treat_missing_data = "missing"
}

# Logs from the EC2 startup script
resource "aws_cloudwatch_log_group" "setup" {
  name              = "/phishing-detector/setup"
  retention_in_days = 7

  tags = {
    Name = "phishing-setup-logs"
  }
}

# Application and Gunicorn error logs
resource "aws_cloudwatch_log_group" "app_errors" {
  name              = "/phishing-detector/app-errors"
  retention_in_days = 7

  tags = {
    Name = "phishing-app-error-logs"
  }
}

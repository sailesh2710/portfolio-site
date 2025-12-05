# =========================
# CloudWatch Log Groups
# =========================

resource "aws_cloudwatch_log_group" "lambda_ec2_scheduler" {
  name              = "/aws/lambda/${aws_lambda_function.ec2_scheduler.function_name}"
  retention_in_days = 14

  lifecycle {
    ignore_changes = [retention_in_days]
  }
}

# =========================
# CloudWatch Alarms
# =========================

resource "aws_cloudwatch_metric_alarm" "eb_cpu_high" {
  alarm_name          = "${local.name_prefix}-eb-high-cpu"
  alarm_description   = "Average CPU > 70% for 2 minutes on the Beanstalk environment"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElasticBeanstalk"
  period              = 60
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    EnvironmentName = aws_elastic_beanstalk_environment.env.name
  }

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "eb_cpu_low" {
  alarm_name          = "${local.name_prefix}-eb-low-cpu"
  alarm_description   = "Average CPU < 20% for 5 minutes on the Beanstalk environment"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElasticBeanstalk"
  period              = 60
  statistic           = "Average"
  threshold           = 20

  dimensions = {
    EnvironmentName = aws_elastic_beanstalk_environment.env.name
  }

  treat_missing_data = "notBreaching"
}

# =========================
# CloudWatch Dashboard
# =========================

resource "aws_cloudwatch_dashboard" "devops_dashboard" {
  dashboard_name = "${local.name_prefix}-devops-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # CPU
      {
        "type" : "metric",
        "x" : 0,
        "y" : 0,
        "width" : 8,
        "height" : 6,
        "properties" : {
          "title" : "EB CPU Utilization",
          "region" : var.aws_region,
          "metrics" : [
            ["AWS/ElasticBeanstalk", "CPUUtilization", "EnvironmentName", aws_elastic_beanstalk_environment.env.name]
          ],
          "stat" : "Average",
          "period" : 60
        }
      },

      # Request Count
      {
        "type" : "metric",
        "x" : 8,
        "y" : 0,
        "width" : 8,
        "height" : 6,
        "properties" : {
          "title" : "EB Request Count",
          "region" : var.aws_region,
          "metrics" : [
            ["AWS/ElasticBeanstalk", "RequestCount", "EnvironmentName", aws_elastic_beanstalk_environment.env.name]
          ],
          "stat" : "Sum",
          "period" : 60
        }
      },

      # Lambda Function
      {
        "type" : "metric",
        "x" : 0,
        "y" : 6,
        "width" : 8,
        "height" : 6,
        "properties" : {
          "title" : "EC2 Scheduler Lambda Invocations / Errors",
          "region" : var.aws_region,
          "metrics" : [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.ec2_scheduler.function_name],
            [".", "Errors", ".", "."]
          ],
          "stat" : "Sum",
          "period" : 300
        }
      },

      # CodePipeline
      {
        "type" : "metric",
        "x" : 0,
        "y" : 12,
        "width" : 16,
        "height" : 6,
        "properties" : {
          "title" : "CodePipeline executions (Succeeded / Failed)",
          "region" : var.aws_region,
          "metrics" : [
            ["AWS/CodePipeline", "ExecutionCount", "PipelineName", aws_codepipeline.pipeline.name, { "stat" : "Sum" }],
            [".", "ExecutionFailed", ".", ".", { "stat" : "Sum" }]
          ],
          "period" : 300
        }
      }
    ]
  })
}
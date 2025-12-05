# ---------------- Lambda packaging ----------------

# Zip lamda/ec2_scheduler.py so Lambda can use it
data "archive_file" "ec2_scheduler_zip" {
  type        = "zip"
  source_file = "${path.module}/lamda/ec2_scheduler.py"
  output_path = "${path.module}/lamda/ec2_scheduler.zip"
}

# ---------------- IAM for Lambda ----------------

resource "aws_iam_role" "ec2_scheduler_role" {
  name = "${local.name_prefix}-ec2-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ec2_scheduler_policy" {
  name = "${local.name_prefix}-ec2-scheduler-policy"
  role = aws_iam_role.ec2_scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Resource = "*"
      }
    ]
  })
}

# ---------------- Lambda function ----------------

resource "aws_lambda_function" "ec2_scheduler" {
  function_name = "${local.name_prefix}-ec2-scheduler"
  description   = "Start/stop dev EC2 instances on a schedule"
  role          = aws_iam_role.ec2_scheduler_role.arn
  handler       = "ec2_scheduler.lambda_handler"
  runtime       = "python3.10"

  filename         = data.archive_file.ec2_scheduler_zip.output_path
  source_code_hash = data.archive_file.ec2_scheduler_zip.output_base64sha256

  timeout = 30
}

# ---------------- EventBridge schedules ----------------
# NOTE: times are in UTC – adjust if you care about local time.

resource "aws_cloudwatch_event_rule" "start_dev_instances" {
  name                = "${local.name_prefix}-start-dev"
  description         = "Start dev EC2 instances at 9 AM (UTC)"
  schedule_expression = "cron(0 9 * * ? *)"
}

resource "aws_cloudwatch_event_rule" "stop_dev_instances" {
  name                = "${local.name_prefix}-stop-dev"
  description         = "Stop dev EC2 instances at 7 PM (UTC)"
  schedule_expression = "cron(0 19 * * ? *)"
}

# ---------------- Event targets (tell Lambda what to do) ----------------

resource "aws_cloudwatch_event_target" "start_target" {
  rule      = aws_cloudwatch_event_rule.start_dev_instances.name
  target_id = "start-dev-ec2"
  arn       = aws_lambda_function.ec2_scheduler.arn

  input = jsonencode({
    action = "start"
  })
}

resource "aws_cloudwatch_event_target" "stop_target" {
  rule      = aws_cloudwatch_event_rule.stop_dev_instances.name
  target_id = "stop-dev-ec2"
  arn       = aws_lambda_function.ec2_scheduler.arn

  input = jsonencode({
    action = "stop"
  })
}

# ---------------- Allow EventBridge to call Lambda ----------------

resource "aws_lambda_permission" "allow_events_start" {
  statement_id  = "AllowExecutionFromEventsStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_dev_instances.arn
}

resource "aws_lambda_permission" "allow_events_stop" {
  statement_id  = "AllowExecutionFromEventsStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_dev_instances.arn
}
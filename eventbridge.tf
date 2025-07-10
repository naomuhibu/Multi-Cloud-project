# =============================================================================
# EVENTBRIDGE RULES
# =============================================================================

# Daily RDS Backup Rule
resource "aws_cloudwatch_event_rule" "daily_rds_backup" {
  name                = "DailyRDSBackup"
  description         = "Trigger Lambda for daily RDS backup"
  schedule_expression = "cron(0 12 * * ? *)"

  tags = {
    Name = "DailyRDSBackup"
  }
}

resource "aws_cloudwatch_event_target" "lambda_backup" {
  rule      = aws_cloudwatch_event_rule.daily_rds_backup.name
  target_id = "LambdaBackupTarget"
  arn       = aws_lambda_function.backup.arn
}

resource "aws_lambda_permission" "allow_eventbridge_backup" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_rds_backup.arn
}

# Daily CloudWatch Logs Export Rule
resource "aws_cloudwatch_event_rule" "daily_cwlogs" {
  name                = "DailyCWlogs"
  description         = "Trigger Lambda for daily CloudWatch logs export"
  schedule_expression = "cron(0 13 * * ? *)"

  tags = {
    Name = "DailyCWlogs"
  }
}

resource "aws_cloudwatch_event_target" "lambda_cwlogs" {
  rule      = aws_cloudwatch_event_rule.daily_cwlogs.name
  target_id = "LambdaCWLogsTarget"
  arn       = aws_lambda_function.cwlogs.arn
}

resource "aws_lambda_permission" "allow_eventbridge_cwlogs" {
  statement_id  = "AllowExecutionFromEventBridgeCWLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cwlogs.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_cwlogs.arn
}

# EC2 State Change Rule
resource "aws_cloudwatch_event_rule" "ec2_state_change" {
  name        = "WordpressServerEC2Rule"
  description = "Capture EC2 instance state changes"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
    detail = {
      state = ["running", "stopped", "terminated"]
    }
  })

  tags = {
    Name = "WordpressServerEC2Rule"
  }
}
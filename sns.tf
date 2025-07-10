# =============================================================================
# SNS TOPIC AND SUBSCRIPTIONS
# =============================================================================

resource "aws_sns_topic" "alerts" {
  name = "YoobeeAlert"

  tags = {
    Name = "YoobeeAlert"
  }
}

resource "aws_cloudwatch_event_target" "sns_ec2_state" {
  rule      = aws_cloudwatch_event_rule.ec2_state_change.name
  target_id = "SNSTarget"
  arn       = aws_sns_topic.alerts.arn

  input_transformer {
    input_paths = {
      instance = "$.detail.instance-id"
      state    = "$.detail.state"
    }
    input_template = "\"EC2 Instance <instance> has changed to <state> state\""
  }
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.alerts.arn
      }
    ]
  })
}
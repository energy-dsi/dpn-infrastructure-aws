resource "aws_sns_topic" "guardduty_findings" {
  name = "${var.project_name}-${var.environment}-guardduty-findings"

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "guardduty_findings_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.guardduty_findings.arn
}

resource "aws_sns_topic_policy" "guardduty_findings" {
  arn = aws_sns_topic.guardduty_findings.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgePublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.guardduty_findings.arn
      }
    ]
  })
}
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "${var.project_name}-${var.environment}-guardduty-findings"
  description = "Capture GuardDuty findings and S3 malware protection scan results"

  event_pattern = jsonencode({
    source = ["aws.guardduty"]

    detail-type = [
      "GuardDuty Finding",
      "GuardDuty Malware Protection Object Scan Result"
    ]
  })

  tags = var.tags
}
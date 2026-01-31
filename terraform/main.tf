provider "aws" {
  region = "us-east-1"
}

# -----------------------------
# IAM Role for Lambda
# -----------------------------
resource "aws_iam_role" "lambda_role" {
  name = "lambda-stop-all-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:DescribeInstances", "ec2:StopInstances"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:*"]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------
# Lambda Function
# -----------------------------
resource "aws_lambda_function" "stop_all_ec2" {
  function_name = "stop-all-ec2-after-2h"
  filename      = "lambda.zip"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30
}

# -----------------------------
# EventBridge Rule (Every 5 min)
# -----------------------------
resource "aws_cloudwatch_event_rule" "every_5_min" {
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule = aws_cloudwatch_event_rule.every_5_min.name
  arn  = aws_lambda_function.stop_all_ec2.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_all_ec2.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_5_min.arn
}

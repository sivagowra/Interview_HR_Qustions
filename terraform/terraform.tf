################################
# Provider
################################
provider "aws" {
  region = "us-east-1"
}

################################
# Variable (only EC2 ID needed)
################################
variable "instance_id" {
  description = "EC2 Instance ID"
  type        = string
}

################################
# SNS Topic
################################
resource "aws_sns_topic" "ec2_hourly" {
  name = "ec2-hourly-alert"
}

# Email Subscription
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.ec2_hourly.arn
  protocol  = "email"
  endpoint  = "gowrasiva12@gmail.com"
}

# SMS Subscription
resource "aws_sns_topic_subscription" "sms" {
  topic_arn = aws_sns_topic.ec2_hourly.arn
  protocol  = "sms"
  endpoint  = "+919493958284"
}

################################
# IAM Role for Lambda
################################
resource "aws_iam_role" "lambda_role" {
  name = "ec2-hourly-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "ec2-hourly-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:DescribeInstances",
        "sns:Publish",
        "logs:*"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

################################
# Lambda Code (Inline)
################################
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "ec2_check.zip"

  source {
    filename = "lambda.py"
    content  = <<EOF
import boto3
import os

ec2 = boto3.client('ec2')
sns = boto3.client('sns')

INSTANCE_ID = os.environ['INSTANCE_ID']
SNS_ARN = os.environ['SNS_ARN']

def lambda_handler(event, context):
    res = ec2.describe_instances(InstanceIds=[INSTANCE_ID])
    state = res['Reservations'][0]['Instances'][0]['State']['Name']

    if state == "running":
        sns.publish(
            TopicArn=SNS_ARN,
            Subject="EC2 Hourly Running Alert",
            Message=f"EC2 Instance {INSTANCE_ID} is RUNNING"
        )
EOF
  }
}

resource "aws_lambda_function" "ec2_check" {
  function_name = "ec2-hourly-check"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda.lambda_handler"
  runtime       = "python3.9"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      INSTANCE_ID = var.instance_id
      SNS_ARN    = aws_sns_topic.ec2_hourly.arn
    }
  }
}

################################
# EventBridge – Every 1 Hour
################################
resource "aws_cloudwatch_event_rule" "hourly" {
  name                = "ec2-hourly-trigger"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule = aws_cloudwatch_event_rule.hourly.name
  arn  = aws_lambda_function.ec2_check.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_check.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.hourly.arn
}

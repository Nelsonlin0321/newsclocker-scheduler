resource "aws_iam_policy" "lambda_sqs_policy" {
  name        = "${local.db_polling_lambda_name}-${local.queue_name}-send-message-policy"
  description = "Policy to allow Lambda to send messages to SQS queue"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sqs:SendMessage"
        Resource = aws_sqs_queue.newsclocker_queue.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_attachment" {
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
  role       = aws_iam_role.iam_for_db_polling_lambda.name
}

resource "aws_sqs_queue" "newsclocker_queue" {
  name                      = "${local.queue_name}"
  delay_seconds             = 0
  max_message_size          = 1024
  message_retention_seconds = 86400
  receive_wait_time_seconds = 20
  visibility_timeout_seconds = 30

  tags = {
    Environment = "${terraform.workspace}"
  }
}
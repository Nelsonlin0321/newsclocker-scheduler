data "aws_iam_policy_document" "insight_workflow_lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

#  Crete role
resource "aws_iam_role" "iam_for_insight_workflow_lambda" {
  name               = "${local.insight_workflow_lambda_name}-iam-role"
  assume_role_policy = data.aws_iam_policy_document.insight_workflow_lambda_assume_role.json
}

# create log group
resource "aws_cloudwatch_log_group" "insight_workflow_lambda_log_group" {
  name              = "/aws/lambda/${local.insight_workflow_lambda_name}"
  retention_in_days = 14
}


#  create log group policy
data "aws_iam_policy_document" "insight_workflow_lambda_log_group_policy_data" {
    statement {
    effect = "Allow"
    actions = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:${local.region}:${local.account_id}:*"]
    
    }
    
    statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["${aws_cloudwatch_log_group.insight_workflow_lambda_log_group.arn}:*"]
  }
}

resource "aws_iam_policy" "insight_workflow_lambda_logging_policy" {
  name        = "${local.insight_workflow_lambda_name}_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.insight_workflow_lambda_log_group_policy_data.json
}

resource "aws_iam_role_policy_attachment" "insight_workflow_lambda_logs_policy_attachment" {
  role       = aws_iam_role.iam_for_insight_workflow_lambda.name
  policy_arn = aws_iam_policy.insight_workflow_lambda_logging_policy.arn
}


data "aws_iam_policy_document" "insight_workflow_lambda_secrets_access" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "insight_workflow_lambda_secrets_policy" {
  name        = "${local.insight_workflow_lambda_name}-secrets"
  path        = "/"
  description = "IAM policy for accessing secrets from Secrets Manager"
  policy      = data.aws_iam_policy_document.insight_workflow_lambda_secrets_access.json
}

resource "aws_iam_role_policy_attachment" "insight_workflow_lambda_secrets_policy_attachment" {
  role       = aws_iam_role.iam_for_insight_workflow_lambda.name
  policy_arn = aws_iam_policy.insight_workflow_lambda_secrets_policy.arn
}


resource "aws_iam_policy" "insight_workflow_lambda_sqs_policy" {
  name        = "${local.insight_workflow_lambda_name}-${local.queue_name}-receive-message-policy"
  description = "Policy to allow Lambda to receive messages from SQS queue"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
                "sqs:ReceiveMessage",
                "sqs:DeleteMessage",
                "sqs:GetQueueAttributes"
            ]
        Resource = "${local.queue_arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "insight_workflow_lambda_sqs_attachment" {
  policy_arn = aws_iam_policy.insight_workflow_lambda_sqs_policy.arn
  role       = aws_iam_role.iam_for_insight_workflow_lambda.name
}

data "aws_iam_policy_document" "insight_workflow_lambda_s3_policy_data" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::cloudfront-aws-bucket/newsclocker/*",
    ]
  }
}


resource "aws_iam_policy" "insight_workflow_lambda_s3_policy" {
  name        = "${local.insight_workflow_lambda_name}_s3"
  path        = "/"
  description = "IAM policy for put object on cloudfront-aws-bucket/newsclocker"
  policy      = data.aws_iam_policy_document.insight_workflow_lambda_s3_policy_data.json
}

resource "aws_iam_role_policy_attachment" "insight_workflow_lambda_s3_attachment" {
  policy_arn = aws_iam_policy.insight_workflow_lambda_s3_policy.arn
  role       = aws_iam_role.iam_for_insight_workflow_lambda.name
}

resource "aws_lambda_function" "insight_workflow_lambda" {
  function_name = "${local.insight_workflow_lambda_name}"
  image_uri     = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/${local.insight_workflow_lambda_name}:latest"

  package_type = "Image"

  role = aws_iam_role.iam_for_insight_workflow_lambda.arn

  # Optional: Set the memory size and timeout
  memory_size = 512
  timeout     = 120
  architectures = ["x86_64"]
  # Optional: Environment variables
  environment {
    variables = {
      ENV  = "${terraform.workspace}"
      BASE_URL = local.base_url
    }
}
  depends_on = [
    aws_cloudwatch_log_group.insight_workflow_lambda_log_group,
    aws_iam_role_policy_attachment.insight_workflow_lambda_logs_policy_attachment,
    aws_iam_role_policy_attachment.insight_workflow_lambda_secrets_policy_attachment,
    aws_iam_role_policy_attachment.insight_workflow_lambda_sqs_attachment,
    aws_iam_role_policy_attachment.insight_workflow_lambda_s3_attachment
  ]
}


resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  event_source_arn = "${local.queue_arn}"
  enabled          = true
  function_name    = "${aws_lambda_function.insight_workflow_lambda.arn}"
  batch_size       = 1
}

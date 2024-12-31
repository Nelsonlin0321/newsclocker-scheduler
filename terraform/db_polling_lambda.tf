data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_db_polling_lambda" {
  name               = "${local.db_polling_lambda_name}-iam-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_cloudwatch_log_group" "db_polling_lambda_log_group" {
  name              = "/aws/lambda/${local.db_polling_lambda_name}"
  retention_in_days = 14
}


data "aws_iam_policy_document" "db_polling_lambda_log_group_logging" {

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

    resources = ["${aws_cloudwatch_log_group.db_polling_lambda_log_group.arn}:*"]
  }
}

resource "aws_iam_policy" "db_polling_lambda_logging_policy" {
  name        = "${local.db_polling_lambda_name}_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.db_polling_lambda_log_group_logging.json
}

resource "aws_iam_role_policy_attachment" "db_polling_lambda_logs_policy_attachment" {
  role       = aws_iam_role.iam_for_db_polling_lambda.name
  policy_arn = aws_iam_policy.db_polling_lambda_logging_policy.arn
}

data "aws_iam_policy_document" "db_polling_lambda_secrets_access" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "db_polling_lambda_secrets_policy" {
  name        = "${local.db_polling_lambda_name}-secrets"
  path        = "/"
  description = "IAM policy for accessing secrets from Secrets Manager"
  policy      = data.aws_iam_policy_document.db_polling_lambda_secrets_access.json
}

resource "aws_iam_role_policy_attachment" "db_polling_lambda_secrets_policy_attachment" {
  role       = aws_iam_role.iam_for_db_polling_lambda.name
  policy_arn = aws_iam_policy.db_polling_lambda_secrets_policy.arn
}


resource "aws_iam_policy" "db_polling_lambda_sqs_policy" {
  name        = "${local.db_polling_lambda_name}-${local.queue_name}-send-message-policy"
  description = "Policy to allow Lambda to send messages to SQS queue"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sqs:SendMessage"
        Resource = "${local.queue_arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "db_polling_lambda_sqs_attachment" {
  policy_arn = aws_iam_policy.db_polling_lambda_sqs_policy.arn
  role       = aws_iam_role.iam_for_db_polling_lambda.name
}


resource "aws_lambda_function" "db_polling_lambda" {
  function_name = "${local.db_polling_lambda_name}"
  image_uri     = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/${local.db_polling_lambda_name}:latest"

  package_type = "Image"

  role = aws_iam_role.iam_for_db_polling_lambda.arn

  # Optional: Set the memory size and timeout
  memory_size = 128
  timeout     = 60
  architectures = ["x86_64"]
  # Optional: Environment variables
  environment {
    variables = {
      ENV  = "${terraform.workspace}"
    }
}
  depends_on = [
    aws_cloudwatch_log_group.db_polling_lambda_log_group,
    aws_iam_role_policy_attachment.db_polling_lambda_logs_policy_attachment,
    aws_iam_role_policy_attachment.db_polling_lambda_secrets_policy_attachment,
    aws_iam_role_policy_attachment.db_polling_lambda_sqs_attachment
  ]
}
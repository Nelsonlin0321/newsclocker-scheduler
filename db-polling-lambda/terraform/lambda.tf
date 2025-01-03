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

resource "aws_iam_role" "iam_for_lambda" {
  name               = "${local.image_name}-${terraform.workspace}-iam-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${local.image_name}-${terraform.workspace}"
  retention_in_days = 14
}


data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [aws_cloudwatch_log_group.lambda_log_group.arn]
  }
}

resource "aws_iam_policy" "lambda_logging_policy" {
  name        = "${local.lambda_function_name}-${terraform.workspace}_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_logging.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs_policy_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

data "aws_iam_policy_document" "lambda_secrets_access" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_secrets_policy" {
  name        = "${local.lambda_function_name}-${terraform.workspace}-secrets"
  path        = "/"
  description = "IAM policy for accessing secrets from Secrets Manager"
  policy      = data.aws_iam_policy_document.lambda_secrets_access.json
}

resource "aws_iam_role_policy_attachment" "lambda_secrets_policy_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_secrets_policy.arn
}

resource "aws_lambda_function" "newsclocker_db_polling" {
  function_name = "${local.lambda_function_name}-${terraform.workspace}"
  image_uri     = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/${local.image_name}-${terraform.workspace}:latest"

  package_type = "Image"

  role = aws_iam_role.iam_for_lambda.arn

  # Optional: Set the memory size and timeout
  memory_size = 512
  timeout     = 120
  architectures = ["x86_64"]
  # Optional: Environment variables
  environment {
    variables = {
      ENV  = "${terraform.workspace}"
    }
}
  depends_on = [
    aws_cloudwatch_log_group.lambda_log_group,
    aws_iam_role_policy_attachment.lambda_logs_policy_attachment,
    aws_iam_role_policy_attachment.lambda_secrets_policy_attachment
  ]
}
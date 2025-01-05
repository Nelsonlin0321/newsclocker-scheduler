resource "aws_cloudwatch_event_rule" "db_polling_trigger_rule" {
    name = "${local.eventbridge_name}"
    description = "trigger newsclocker polling lambda"
    schedule_expression = "rate(3 minutes)"
}

resource "aws_cloudwatch_event_target" "db_polling_trigger_rule_lambda_target" {
  arn = aws_lambda_function.db_polling_lambda.arn
  rule = aws_cloudwatch_event_rule.db_polling_trigger_rule.name
}

resource "aws_lambda_permission" "allow_cloudwatch_to_trigger_db_polling_lambda" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.db_polling_lambda.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.db_polling_trigger_rule.arn
}
# constant settings
locals {
  account_id="932682266260"
  region="us-east-1"
}


locals {
  db_polling_lambda_name = "newsclocker-db-polling-lambda-${terraform.workspace}"
}

locals {
  queue_name = "newsclocker-${terraform.workspace}"
}

locals {
  queue_arn = "arn:aws:sqs:us-east-1:932682266260:newsclocker-${terraform.workspace}"
}

locals {
  insight_workflow_lambda_name = "newsclocker-insight-workflow-lambda-${terraform.workspace}"
}

locals {
  eventbridge_name = "newsclocker-subscription-schedule-${terraform.workspace}"
}
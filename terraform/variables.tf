# constant settings
locals {
  account_id="932682266260"
  region="us-east-1"
}


locals {
  db_polling_lambda_name = "newsclocker-db-polling-lambda-${terraform.workspace}"
}

locals {
  queue_name = "newsclocker-queue-${terraform.workspace}"
}
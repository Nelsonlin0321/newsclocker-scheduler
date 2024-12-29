# constant settings
locals {
  image_name    = "newsclocker-db-polling-lambda"
  image_version = "latest"
  lambda_function_name = "newsclocker-db-polling-lambda"
  account_id="932682266260"
  region="us-east-1"
}


# variable "environment" {
#     description = "The environment to deploy"
#     type        = string
# }
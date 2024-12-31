resource "aws_ecr_repository" "newsclocker_db_polling_lambda_repository" {
  name                 = "${local.db_polling_lambda_name}"
  image_tag_mutability = "MUTABLE"
  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "aws_ecr_repository" "newsclocker_insight_workflow_lambda_repository" {
  name                 = "${local.insight_workflow_lambda_name}"
  image_tag_mutability = "MUTABLE"
  # lifecycle {
  #   prevent_destroy = true
  # }
}
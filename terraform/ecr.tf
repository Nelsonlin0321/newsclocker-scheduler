resource "aws_ecr_repository" "newsclocker_db_lambda_polling_repository" {
  name                 = "${local.db_polling_lambda_name}"
  image_tag_mutability = "MUTABLE"
}
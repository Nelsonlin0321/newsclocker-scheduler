resource "aws_ecr_repository" "newsclocker_db_lambda_polling_repository" {
  name                 = "${local.image_name}-${var.environment}"
  image_tag_mutability = "MUTABLE"
}
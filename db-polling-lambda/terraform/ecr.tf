resource "aws_ecr_repository" "newsclocker_db_lambda_polling_repository" {
  name                 = "${local.image_name}-${terraform.workspace}"
  image_tag_mutability = "MUTABLE"
}
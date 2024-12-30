resource "aws_ecr_repository" "newsclocker_db_lambda_polling_repository" {
  name                 = "${local.db_polling_lambda_name}"
  image_tag_mutability = "MUTABLE"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ecr_repository" "newsclocker_news_ai_agent_repository" {
  name                 = "${local.news_ai_agent_lambda_name}"
  image_tag_mutability = "MUTABLE"
  lifecycle {
    prevent_destroy = true
  }
}
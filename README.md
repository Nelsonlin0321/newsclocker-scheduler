# newsclocker-scheduler



## Terraform init
```shell
terraform init

terraform workspace new dev
terraform workspace new prod
terraform workspace select dev
```

```shell
terraform workspace select dev
terraform apply -target=aws_ecr_repository.newsclocker_db_lambda_polling_repository
```

```shell
terraform apply
```
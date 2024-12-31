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
terraform apply -target=aws_ecr_repository.newsclocker_db_polling_lambda_repository \
                -target=aws_ecr_repository.newsclocker_insight_workflow_lambda_repository
```

```shell
terraform apply -target=aws_lambda_function.db_polling_lambda
```


```shell
```

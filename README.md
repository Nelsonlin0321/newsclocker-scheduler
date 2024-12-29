# newsclocker-scheduler



## Terraform init
```shell
terraform init

terraform workspace new dev
terraform workspace new prod
terraform workspace select dev
```

```shell
terraform apply


```shell
terraform workspace select dev
terraform apply -target=aws_lambda_function.newsclocker_db_polling
```
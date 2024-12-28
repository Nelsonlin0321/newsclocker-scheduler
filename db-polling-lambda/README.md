## DB Polling Lambda

## .env

```shell
export ENV=dev
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
```

## Setup
```shell
# create a python environment
python -m venv .venv
source .venv/bin/activate

uv init

uv pip install -r pyproject.toml
```

# Run
```shell
source .venv/bin/activate
source .env
python main.py
```


## Build and Run Docker
```shell
source .env
docker build -t ${IMAGE_NAME}-${ENV}:latest -f ./Dockerfile.aws.lambda . --platform linux/amd64
docker run --env-file .env.docker ${IMAGE_NAME}-${ENV}:latest
```



## Terraform init
```shell
terraform init

terraform workspace new dev
terraform workspace new prod
terraform workspace select dev
```

```shell
terraform apply -target=aws_ecr_repository.newsclocker_db_lambda_polling_repository
```

```shell
source .env
aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com

docker tag ${IMAGE_NAME}-${ENV}:latest ${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_NAME}-${ENV}:latest
docker push ${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_NAME}-${ENV}:latest
```


```shell
terraform workspace select dev
terraform apply -target=aws_lambda_function.newsclocker_db_polling
```
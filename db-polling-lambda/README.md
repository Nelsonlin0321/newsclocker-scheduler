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
image_name=newsclocker-lambda-polling
docker build -t ${image_name}:latest -f ./Dockerfile . --platform linux/amd64
docker run --env-file .env.docker ${image_name}:latest
```

```shell
terraform init
terraform apply -target=aws_ecr_repository.newsclocker_db_lambda_polling_repository
```
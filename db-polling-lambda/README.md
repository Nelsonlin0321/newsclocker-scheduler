## DB Polling Lambda

## .env

```shell
export ENV=dev
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export ACCOUNT_ID=
export IMAGE_NAME=
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

# Push ECR
```shell
source .env
aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com

docker tag ${IMAGE_NAME}-${ENV}:latest ${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_NAME}-${ENV}:latest
docker push ${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_NAME}-${ENV}:latest
```
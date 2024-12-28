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
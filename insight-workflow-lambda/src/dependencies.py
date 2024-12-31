import os
from openai import OpenAI
from pymongo import MongoClient
from src.aws_utils import get_secret
ENV = os.getenv("ENV")

mongodb_url = get_secret(f"{ENV}/newsclocker/mongodb")

deep_seek_api_key = get_secret(
    f"{ENV}/newsclocker/deepseek_api_key")


def get_db():
    mongodb_client = MongoClient(mongodb_url)
    db = mongodb_client['default']
    return db


def get_openai_client():
    client = OpenAI(api_key=deep_seek_api_key,
                    base_url="https://api.deepseek.com")
    return client

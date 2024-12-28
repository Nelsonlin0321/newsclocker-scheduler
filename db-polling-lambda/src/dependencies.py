import os
from pymongo import MongoClient

from src.aws_utils import get_secret

ENV = os.getenv("ENV")


def get_db():

    secret_name = f"{ENV}/newsclocker/mongodb"

    mongodb_url = get_secret(secret_name)

    mongodb_client = MongoClient(mongodb_url)
    db = mongodb_client['default']
    return db

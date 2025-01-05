import os
from loguru import logger
import httpx

from src.aws_utils import get_secret
BASE_URL = os.getenv("BASE_URL")
ENV = os.getenv("ENV")


API_KEY = get_secret(f"{ENV}/newsclocker/backend_api_key")


def send_email(mailId: str):
    headers = {
        'X-API-KEY': API_KEY,
        'Content-Type': 'application/json'
    }
    response = httpx.get(
        BASE_URL + f"/api/mail/{mailId}", headers=headers, timeout=60)

    if response.status_code == 200:
        return response.json()
    else:
        logger.error(f"Failed to send email with the error: {response.text}")

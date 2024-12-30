import os
from loguru import logger
import httpx
BASE_URL = os.getenv("BASE_URL")
API_KEY = os.getenv("API_KEY")


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

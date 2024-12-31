import traceback

from loguru import logger
from main import main


def handler(event, context):
    records = event['Records']
    for record in records:
        subscriptionId = record['body']
        try:
            main(subscriptionId)
        except Exception as e:
            error_details = traceback.format_exc()
            error_message = f"""Subscription: {
                subscriptionId} news insight unable to processed error: {e} {error_details}"""
            logger.error(error_message)

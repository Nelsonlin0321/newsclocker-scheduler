import os
import traceback
from loguru import logger
from datetime import datetime, timedelta, timezone
from tqdm import tqdm
from src.aws_utils import send_message_to_queue
from src.dependencies import get_db

INTERVAL_MINUTES = int(os.getenv("INTERVAL", "5"))

FREQUENCY_TO_DELTA_DICT = {
    "every_12_hour": timedelta(hours=12),
    "every_day": timedelta(days=1),
    "every_week": timedelta(days=7)
}


def main():
    left_datetime = datetime.now(
        timezone.utc)

    right_datetime = left_datetime + timedelta(seconds=INTERVAL_MINUTES*60)

    logger.info("Starting Polling.")
    db = get_db()
    subscriptions = list(db['NewsSubscription'].find({
        '$and': [{
            'status': {'$ne': 'RUNNING'},
            'nextRunTime': {
                '$gte': left_datetime,
                '$lte': right_datetime
            }
        }]
    }))

    for sub in tqdm(subscriptions):
        try:
            subscriptionId = sub["_id"]
            send_message_to_queue(subscriptionId)
            next_run_time = sub['nextRunTime']
            frequency = sub['frequency']
            updated_next_run_time = next_run_time + \
                FREQUENCY_TO_DELTA_DICT[frequency]
            db['NewsSubscription'].update_one(
                filter={"_id": subscriptionId},
                update={"$set": {"nextRunTime": updated_next_run_time}}
            )
        except Exception as e:
            error_details = traceback.format_exc()
            error_message = f"""Subscription: {
                subscriptionId} unable to be triggered with error: {e} {error_details}"""
            logger.error(error_message)

    logger.info("Polling Completed.")


if __name__ == "__main__":
    main()

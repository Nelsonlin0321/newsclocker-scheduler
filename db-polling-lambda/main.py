import os
from loguru import logger
from datetime import datetime, timedelta, timezone
from tqdm import tqdm
from src.aws_utils import send_message_to_queue
from src.dependencies import get_db

INTERVAL_MINUTES = int(os.getenv("INTERVAL", "5"))


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
        subscriptionId = sub["_id"]
        send_message_to_queue(subscriptionId)
        db['NewsSubscription'].update_one(
            {"_id": subscriptionId, "status": "RUNNING"})
    logger.info("Polling Completed.")


if __name__ == "__main__":
    main()

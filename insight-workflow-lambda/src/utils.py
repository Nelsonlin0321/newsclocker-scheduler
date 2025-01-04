import os
import re
import boto3
import traceback
from loguru import logger
import pandas as pd
from concurrent.futures import ThreadPoolExecutor
from typing import List
from tqdm import tqdm
from datetime import datetime, timedelta


def process_keywords(keywords: List[str], news_sources: List[str]):
    q = " OR ".join(sorted([k.lower().strip() for k in keywords]))
    news_sources = " OR ".join(
        [f"site:{n}".lower() for n in sorted(news_sources)])
    query = q + " " + news_sources
    return query


def multi_threading(function, parameters, max_workers=5, desc=""):
    pbar = tqdm(total=len(parameters), desc=desc, leave=True, position=0)
    event = []
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        # not need chucksize
        for result in executor.map(function, parameters):
            event.append(result)
            pbar.update(1)
    pbar.close()

    return event


def convert_distance_to_now(distance_str: str) -> datetime:

    try:
        match = re.match(r'(\d+)\s+(\w+)\s+ago', distance_str)
        if match:
            value = int(match.group(1))
            unit = match.group(2).lower()

            # Map the unit to timedelta
            if unit.startswith('hour'):
                delta = timedelta(hours=value)
            elif unit.startswith('minute'):
                delta = timedelta(minutes=value)
            elif unit.startswith('second'):
                delta = timedelta(seconds=value)
            elif unit.startswith('day'):
                delta = timedelta(days=value)
            elif unit.startswith('week'):
                delta = timedelta(weeks=value)
            elif unit.startswith('month'):
                delta = timedelta(days=30*value)
            elif unit.startswith('year'):
                delta = timedelta(days=365*value)
            else:
                raise ValueError("Unsupported time unit")

            return datetime.now() - delta
        else:
            date_object = pd.to_datetime(distance_str).to_pydatetime()

            return date_object
    except Exception as e:
        error_details = traceback.format_exc()
        logger.error(f"Error:{e} with the details:{error_details}")
        return datetime.now() - timedelta(weeks=1)


def upload_file_to_s3(file_path, bucket_name="cloudfront-aws-bucket", s3_folder="newsclocker/insight-pdf"):

    file_name = os.path.basename(file_path)
    s3_client = boto3.client('s3')
    s3_path = os.path.join(s3_folder, file_name)

    s3_client.upload_file(file_path, bucket_name, s3_path)
    logger.info(f"Uploaded {file_path} to s3://{bucket_name}/{s3_path}")

    return f"https://d2gewc5xha837s.cloudfront.net/{s3_path}"


def sanitize_filename(filename: str) -> str:
    # Replace any character that is not alphanumeric or underscore with an underscore
    sanitized = re.sub(r'\W', '_', filename)
    return sanitized


def get_reference_links(urls):
    urls_with_references_title = ' \n \n **Reference Links:** \n ' + \
        " \n ".join(urls)
    return urls_with_references_title

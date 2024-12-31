import os
import json
import requests
from src import utils
from src.aws_utils import get_secret


URL = "https://google.serper.dev/news"
ENV = os.environ.get("ENV")

SERPER_API_KEY = get_secret(f"{ENV}/newsclocker/serper_api_key")


def search_news(q, gl="us", hl="en", num=10, tbs="qdr:d"):
    payload = json.dumps({
        "q": q,
        "gl": gl,
        "hl": hl,
        "num": num,
        "tbs": tbs
    })
    headers = {
        'X-API-KEY': SERPER_API_KEY,
        'Content-Type': 'application/json'
    }

    response = requests.post(URL, headers=headers, data=payload)  # noqa: F821

    search_result = response.json()

    for news in search_result['news']:
        news['date'] = utils.convert_distance_to_now(news['date']).isoformat()

    return search_result

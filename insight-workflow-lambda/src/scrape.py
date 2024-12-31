import re
import traceback
from bs4 import BeautifulSoup
import httpx
from loguru import logger
from src.utils import multi_threading


class Scraper():
    def __init__(self):
        self.headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
            "Accept-Language": "en-US,en;q=0.9",
            "Referer": "https://www.google.com/",
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1",
        }

    def run(self, url):
        try:
            response = httpx.get(
                url,
                timeout=15,
                headers=self.headers
            )

            # response.encoding = response.apparent_encoding
            parsed = BeautifulSoup(response.text, "html.parser")

            text = parsed.get_text(" ")
            text = re.sub('[ \t]+', ' ', text)
            text = re.sub('\\s+\n\\s+', '\n', text)
            return text
        except Exception as e:
            error_details = traceback.format_exc()
            logger.error(f"Error:{e} with the details:{error_details}")
            return ""

    def multi_run(self, urls):
        contents = multi_threading(self.run, urls, max_workers=5)
        return contents


import datetime
from copy import deepcopy
import json
import cuid
from src.chat import get_chat_response
from src.markdown_to_pdf import generate_pdf
from src.prompts import get_prompt, system_prompt, title_prompt
from src.search_news import search_news
from src.dependencies import get_db
from src.scrape import Scraper
from src.send_email import send_email
from src.utils import get_reference_links, process_keywords
from loguru import logger

scraper = Scraper()

date_range_map = {
    "any_time": None,
    "past_hour": "qdr:h",
    "past_24_hours": "qdr:d",
    "past_week": "qdr:w",
    "past_month": "qdr:m",
    "past_year": "qdr:y",
}

NUM_ARTICLES = 10


def perform_search(subscription, query):
    return search_news(
        q=query,
        gl=subscription['country'],
        hl=subscription['language'],
        num=NUM_ARTICLES,
        tbs=date_range_map[subscription['dateRange']]
    )


def prepare_articles(news, contents):
    relevant_articles = deepcopy(news)
    for article, content in zip(relevant_articles, contents):
        article.pop("imageUrl")
        article['content'] = content
    return relevant_articles


def main(subscription_id: str):

    db = get_db()
    # openai_client = get_openai_client()

    subscription = db['NewsSubscription'].find_one({"_id": subscription_id})
    if not subscription:
        logger.error(f"Subscription {subscription_id} not found")
        return {"status": "error", "detail": f"Subscription {subscription_id} not found"}

    query = process_keywords(
        subscription["keywords"], subscription["newsSources"])

    logger.info(f"Performing search for query: {query}")
    search_result = perform_search(subscription, query)

    urls = [new['link']for new in search_result['news']]

    logger.info(f"Found {len(urls)} articles, fetching contents...")
    contents = scraper.multi_run(urls=urls)

    relevant_articles = prepare_articles(search_result['news'], contents)

    user_prompt = subscription['newsPrompt']
    new_articles = json.dumps(relevant_articles)

    prompt = get_prompt(user_prompt, new_articles)

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": prompt},
    ]

    logger.info("Getting chat response for user prompt")
    ai_insight = get_chat_response(messages)

    reference_links_str = get_reference_links(
        [news['link'] for news in search_result['news']])

    ai_insight = ai_insight+reference_links_str

    messages = [
        {"role": "assistant", "content": ai_insight},
        {"role": "user", "content": title_prompt},
    ]

    logger.info("Getting title from chat response")
    title = get_chat_response(messages)

    createdAt = datetime.datetime.now(datetime.timezone.utc)

    logger.info("Generating PDF for the insights")
    pdfUrl = generate_pdf(ai_insight, title)

    payload_to_insert = {
        "_id": cuid.cuid(),
        "createdAt": createdAt,
        "newsSubscriptionId": subscription_id,
        "scrapeContent": contents,
        "searchResult": search_result,
        "content": ai_insight,
        "title": title,
        "pdfUrl": pdfUrl,
        "isRead": False,
        "isStarred": False,
        "isTrashed": False,
    }
    logger.info("Inserting mail into the database")
    mail = db['Mail'].insert_one(payload_to_insert)
    mail_id = mail.inserted_id

    logger.info("Mail generated successfully with id: {}", mail_id)

    _ = send_email(mail_id)

    return {"status": "success",
            "detail": "Task to execute news insight is compeleted",
            "data": {"mailId": mail_id}}

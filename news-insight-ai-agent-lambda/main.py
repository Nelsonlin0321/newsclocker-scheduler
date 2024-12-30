
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
from src.utils import process_keywords

date_range_map = {
    "any_time": None,
    "past_hour": "qdr:h",
    "past_24_hours": "qdr:d",
    "past_week": "qdr:w",
    "past_month": "qdr:m",
    "past_year": "qdr:y",
}

NUM_ARTICLES = 10


def main(subscription_id: str):

    db = get_db()
    # openai_client = get_openai_client()

    subscription = db['NewsSubscription'].find_one({"_id": subscription_id})
    if not subscription:
        return {"status": "error", "detail": f"Subscription {subscription_id} not found"}

    query = process_keywords(
        subscription["keywords"], subscription["newsSources"])

    q = query
    gl = subscription['country']
    hl = subscription['language']
    num = NUM_ARTICLES
    tbs = date_range_map[subscription['dateRange']]

    search_result = search_news(q=q, gl=gl, hl=hl, num=num, tbs=tbs)

    scraper = Scraper()

    urls = [new['link']for new in search_result['news']]

    contents = scraper.multi_run(urls=urls)

    relevant_articles = deepcopy(search_result['news'])
    for article, content in zip(relevant_articles, contents):
        article.pop("imageUrl")
        article['content'] = content

    news_reference = [{"link": news['link']} for news in search_result['news']]

    user_prompt = subscription['newsPrompt']
    new_articles = json.dumps(relevant_articles)
    news_reference = json.dumps(news_reference)

    prompt = get_prompt(user_prompt, new_articles, news_reference)

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": prompt},
    ]

    ai_insight = get_chat_response(messages)

    messages = [
        {"role": "assistant", "content": ai_insight},
        {"role": "user", "content": title_prompt},
    ]

    title = get_chat_response(messages)

    createdAt = datetime.datetime.now(datetime.timezone.utc)

    newsSubscriptionId = subscription_id
    scrapeContent = contents
    searchResult = search_result
    content = ai_insight

    pdfUrl = generate_pdf(content, title)

    payload_to_insert = {
        "_id": cuid.cuid(),
        "createdAt": createdAt,
        "newsSubscriptionId": newsSubscriptionId,
        "scrapeContent": scrapeContent,
        "searchResult": searchResult,
        "content": content,
        "title": title,
        "pdfUrl": pdfUrl,
        "isRead": False,
        "isStarred": False,
        "isTrashed": False,
    }

    mail = db['Mail'].insert_one(payload_to_insert)
    mail_id = mail.inserted_id

    return {"status": "success", "detail": f"The mail f{mail_id} has been generated."}

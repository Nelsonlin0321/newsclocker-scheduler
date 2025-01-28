from typing import Dict, List
from src.dependencies import get_openai_client


def get_chat_response(messages: List[Dict]):
    client = get_openai_client()
    response = client.chat.completions.create(
        model="deepseek-reasoner",
        messages=messages,
        stream=False
    )
    return response.choices[0].message.content

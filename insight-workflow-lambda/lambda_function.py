from main import main


def handler(event, context):
    records = event['Records']
    for record in records:
        mailId = record['body']
        main(mailId)

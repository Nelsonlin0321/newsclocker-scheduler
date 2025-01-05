import os
import boto3
ENV = os.getenv("ENV")


def get_secret(secret_name: str):

    # secret_name = f"{ENV}/newsclocker/mongodb"
    region_name = "us-east-1"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )
    get_secret_value_response = client.get_secret_value(
        SecretId=secret_name
    )
    secret = get_secret_value_response['SecretString']
    return secret


env_queue_url_dict = {
    "dev": 'https://sqs.us-east-1.amazonaws.com/932682266260/newsclocker-dev',
    "prod": 'https://sqs.us-east-1.amazonaws.com/932682266260/newsclocker-prod',
}


def send_message_to_queue(message_body):

    sqs = boto3.client('sqs')

    queue_url = env_queue_url_dict[ENV]

    response = sqs.send_message(
        QueueUrl=queue_url,
        MessageBody=message_body
    )

    return response

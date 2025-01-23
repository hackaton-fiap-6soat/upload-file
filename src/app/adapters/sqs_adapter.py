import json
import boto3
import os
from app.ports.sqs_port import QueuePort

class SQSAdapter(QueuePort):
    def __init__(self):
        self.sqs_client = boto3.client('sqs')
        self.queue_url = os.environ['SQS_URL']

    def send_message(self, message: dict) -> None:
        self.sqs_client.send_message(
            QueueUrl=self.queue_url,
            MessageBody=json.dumps(message)
        )
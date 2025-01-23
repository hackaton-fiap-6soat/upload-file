import boto3
import os
from app.ports.s3_port import StoragePort

class S3Adapter(StoragePort):
    def __init__(self):
        self.s3_client = boto3.client('s3')
        self.bucket_name = os.environ['S3_BUCKET_NAME']

    def generate_presigned_url(self, file_name: str, content_type: str) -> str:
        return self.s3_client.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': self.bucket_name,
                'Key': file_name,
                'ContentType': content_type
            },
            ExpiresIn=3600
        )
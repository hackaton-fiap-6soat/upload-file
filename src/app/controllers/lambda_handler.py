import json
from app.domain.entities import File
from app.domain.services import UploadService
from app.adapters.s3_adapter import S3Adapter
from app.adapters.sqs_adapter import SQSAdapter

def lambda_handler(event, context):
    try:
        # Extrair informações da requisição
        body = json.loads(event['body'])
        file_name = body['file_name']
        file_size = body['file_size']
        content_type = body['content_type']

        # Instanciar dependências
        s3_adapter = S3Adapter()
        sqs_adapter = SQSAdapter()
        upload_service = UploadService(s3_adapter, sqs_adapter, max_file_size=100 * 1024 * 1024)

        # Criar entidade do arquivo e processar o upload
        file = File(name=file_name, size=file_size, content_type=content_type)
        upload_url = upload_service.upload_file(file)

        # Retornar URL pré-assinada
        return {
            'statusCode': 200,
            'body': json.dumps({'upload_url': upload_url})
        }
    except ValueError as e:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': str(e)})
        }
    except Exception as e:
        print(e)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }
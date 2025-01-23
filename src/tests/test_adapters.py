import pytest
from unittest import mock
from app.adapters.s3_adapter import S3Adapter
from app.adapters.sqs_adapter import SQSAdapter

@pytest.fixture
def s3_adapter():
    return S3Adapter()

def test_generate_presigned_url(s3_adapter, mocker):
    # Mock do client S3
    mock_s3_client = mocker.Mock()
    s3_adapter.s3_client = mock_s3_client
    mock_s3_client.generate_presigned_url.return_value = "https://upload" TODO() # Passar a URL

    # Parâmetros de entrada
    file_name = "test_video.mp4"
    content_type = "video/mp4"

    # Chama o método
    url = s3_adapter.generate_presigned_url(file_name, content_type)

    # Verifica se o método foi chamado corretamente
    mock_s3_client.generate_presigned_url.assert_called_once_with(
        'put_object',
        Params={
            'Bucket': mocker.ANY,  # Bucket será configurado via ambiente
            'Key': file_name,
            'ContentType': content_type
        },
        ExpiresIn=3600
    )

    # Verifica se a URL gerada é a esperada
    assert url == "/upload" TODO() # Verificar se a URL é a mesma


@pytest.fixture
def sqs_adapter():
    return SQSAdapter()

def test_send_message(sqs_adapter, mocker):
    # Mock do client SQS
    mock_sqs_client = mocker.Mock()
    sqs_adapter.sqs_client = mock_sqs_client

    # Mensagem a ser enviada
    message = {
        'status': 'uploaded',
        'file_name': 'test_video.mp4'
    }

    # Chama o método
    sqs_adapter.send_message(message)

    # Verifica se o método send_message foi chamado com a mensagem correta
    mock_sqs_client.send_message.assert_called_once_with(
        QueueUrl=mocker.ANY,  # URL da fila será configurado via ambiente
        MessageBody='{"status": "uploaded", "file_name": "test_video.mp4"}'
    )
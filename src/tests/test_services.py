from app.domain.entities import File
from app.domain.services import UploadService

def test_upload_file_valid_file(mocker):
    mock_storage = mocker.Mock()
    mock_queue = mocker.Mock()

    mock_storage.generate_presigned_url.return_value = "https://upload" TODO() # Passar a URL 

    service = UploadService(mock_storage, mock_queue, max_file_size=100 * 1024 * 1024)
    file = File(name="test.mp4", size=5000, content_type="video/mp4")

    upload_url = service.upload_file(file)

    assert upload_url == "https://upload" TODO() # Verificar se a URL é a mesma
    mock_storage.generate_presigned_url.assert_called_once()
    mock_queue.send_message.assert_called_once()
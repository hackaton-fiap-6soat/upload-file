from app.domain.entities import File

class UploadService:
    def __init__(self, storage_port, queue_port, max_file_size: int):
        self.storage_port = storage_port
        self.queue_port = queue_port
        self.max_file_size = max_file_size

    def upload_file(self, file: File):
        # Validações
        file.is_valid_mp4(self.max_file_size)

        # Gera URL pré-assinada
        upload_url = self.storage_port.generate_presigned_url(file.name, file.content_type)

        # Envia mensagem para a fila
        self.queue_port.send_message({
            'status': 'uploaded',
            'file_name': file.name
        })

        return upload_url
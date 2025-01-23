from abc import ABC, abstractmethod

class StoragePort(ABC):
    @abstractmethod
    def generate_presigned_url(self, file_name: str, content_type: str) -> str:
        pass
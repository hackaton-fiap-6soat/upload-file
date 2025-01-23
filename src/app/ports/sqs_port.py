from abc import ABC, abstractmethod

class QueuePort(ABC):
    @abstractmethod
    def send_message(self, message: dict) -> None:
        pass
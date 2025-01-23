class File:
    def __init__(self, name: str, size: int, content_type: str):
        self.name = name
        self.size = size
        self.content_type = content_type

    def is_valid_mp4(self, max_size: int) -> bool:
        if self.content_type != 'video/mp4':
            raise ValueError("Only .mp4 files are allowed.")
        if self.size > max_size:
            raise ValueError("File size exceeds the allowed limit.")
        return True
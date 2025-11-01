from pydantic import BaseModel

class MarkReadRequest(BaseModel):
    notification_id: int
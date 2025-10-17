from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class NotificationModel(BaseModel):
    id: Optional[int] = None
    user_id: str
    title: str
    message: str
    type: str = "info"  # info, success, warning, error
    timestamp: datetime = Field(default_factory=datetime.utcnow)  # ✅ CORRECTION
    is_read: bool = False
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()  # Format ISO8601 pour JSON
        }
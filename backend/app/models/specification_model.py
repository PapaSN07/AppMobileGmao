from sqlalchemy import Integer, Text
from sqlalchemy.orm import declarative_base

from typing import Any, Dict
from sqlalchemy import Column, String

Base = declarative_base()

class Specification(Base):
    """Modèle SQLAlchemy pour t_specification selon EQUIPMENT_T_SPECIFICATION_QUERY"""
    __tablename__ = 't_specification'
    __table_args__ = {'schema': 'dbo'}
    
    pk_specification = Column(Integer, primary_key=True, autoincrement=True)
    cwsp_code = Column(String(50), nullable=False, unique=True)
    cwsp_description = Column(Text, nullable=True)

    def to_dict(self) -> Dict[str, Any]:
        return {
            'pk_specification': self.pk_specification,
            'code': self.cwsp_code,
            'description': self.cwsp_description
        }
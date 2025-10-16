from sqlalchemy import Integer, Text
from sqlalchemy.orm import declarative_base

from typing import Any, Dict
from sqlalchemy import Column, String

Base = declarative_base()

class AttributeValues(Base):
    """Modèle SQLAlchemy pour attribute_values selon ATTRIBUTE_VALUES_QUERY"""
    __tablename__ = 'attribute_values'
    __table_args__ = {'schema': 'dbo'}
    
    pk_attribute_values = Column(Integer, primary_key=True, autoincrement=True)
    cwav_specification = Column(String(50), nullable=False)
    cwav_attribute_index = Column(String(10), nullable=False)
    cwav_value = Column(Text, nullable=False)

    @classmethod
    def from_db_row(cls, row: tuple) -> 'AttributeValues':
        """Crée depuis ATTRIBUTE_VALUES_QUERY"""
        attr_val = cls()
        attr_val.pk_attribute_values = int(row[0]) if row[0] is not None else None
        attr_val.cwav_value = str(row[1]) if row[1] is not None else ""
        return attr_val

    def to_dict(self) -> Dict[str, Any]:
        return {
            'id': str(self.pk_attribute_values) if self.pk_attribute_values is not None else None,
            'specification': self.cwav_specification,
            'attribute_index': self.cwav_attribute_index,
            'value': self.cwav_value
        }
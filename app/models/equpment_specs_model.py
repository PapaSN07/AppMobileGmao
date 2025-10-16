from sqlalchemy import Date, Integer, func
from sqlalchemy.orm import declarative_base

from typing import Any, Dict
from sqlalchemy import Column, String

Base = declarative_base()

class EquipmentSpecs(Base):
    """Modèle SQLAlchemy pour equipment_specs selon EQUIPMENT_SPEC_ADD_QUERY"""
    __tablename__ = 'equipment_specs'
    __table_args__ = {'schema': 'dbo'}
    
    id = Column('pk_equipment_specs', Integer, primary_key=True, autoincrement=True)
    etes_specification = Column(String(50), nullable=False)  # cwsp_code
    etes_equipment = Column(String(50), nullable=False)      # ereq_code
    etes_release_date = Column(Date, default=func.now())
    etes_release_number = Column(Integer, default=1)

    def to_dict(self) -> Dict[str, Any]:
        return {
            'id': str(self.id) if self.id is not None else None,
            'specification': self.etes_specification,
            'equipment': self.etes_equipment,
            'release_date': self.etes_release_date.isoformat() if self.etes_release_date is not None else None,
            'release_number': self.etes_release_number
        }
from sqlalchemy import Integer
from sqlalchemy.orm import declarative_base

from typing import Any, Dict
from sqlalchemy import Column, String, Text

Base = declarative_base()


class UniteModel(Base):
    """Modèle SQLAlchemy pour les unités organisationnelles."""
    # ✅ CORRECTION: Table selon FUNCTION_QUERY
    __tablename__ = 'function_'
    __table_args__ = {'schema': 'dbo'}
    
    id = Column('pk_function_', Integer, primary_key=True, autoincrement=True)
    code = Column('mdfn_code', String(50), nullable=False)
    description = Column('mdfn_description', Text, nullable=False)
    entity = Column('mdfn_entity', String(50), nullable=True)
    parent_function = Column('mdfn_parent_function', String(50), nullable=True)  # ✅ CORRECTION
    system_function = Column('mdfn_system_function', String(50), nullable=True)  # ✅ CORRECTION

    @classmethod
    def from_db_row(cls, row: tuple) -> 'UniteModel':
        """Crée depuis FUNCTION_QUERY"""
        unite = cls()
        unite.id = int(row[0]) if row[0] is not None else None
        unite.code = str(row[1]) if row[1] is not None else ""
        unite.description = str(row[2]) if row[2] is not None else ""
        unite.entity = str(row[3]) if len(row) > 3 and row[3] is not None else None
        unite.parent_function = str(row[4]) if len(row) > 4 and row[4] is not None else None
        unite.system_function = str(row[5]) if len(row) > 5 and row[5] is not None else None
        return unite

    def to_dict(self) -> Dict[str, Any]:
        return {
            'id': str(self.id) if self.id is not None else None,
            'code': self.code,
            'description': self.description,
            'entity': self.entity,
            'parent_function': self.parent_function,
            'system_function': self.system_function
        }
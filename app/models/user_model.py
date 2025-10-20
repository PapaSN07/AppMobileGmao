from sqlalchemy import Boolean, Date, ForeignKey, Integer, Text, false, func

from typing import Any, Dict
from sqlalchemy import Column, String

# Importer les deux bases depuis engine
from app.db.sqlalchemy.engine import Base, BaseClicClac

class UserModel(Base):
    """Modèle SQLAlchemy pour les utilisateurs."""
    # ✅ CORRECTION: Table selon GET_USER_AUTHENTICATION_QUERY
    __tablename__ = 'coswin_user'
    __table_args__ = {'schema': 'dbo'}
    
    id = Column('pk_coswin_user', Integer, primary_key=True, autoincrement=True)
    code = Column('cwcu_code', String(50), nullable=False)
    username = Column('cwcu_signature', String(100), nullable=False)
    password = Column('cwcu_password', String(255), nullable=True)
    email = Column('cwcu_email', String(255), nullable=True)
    entity = Column('cwcu_entity', String(50), nullable=True)
    group = Column('cwcu_preferred_group', String(50), nullable=True)
    url_image = Column('cwcu_url_image', String(500), nullable=True)
    is_absent = Column('cwcu_is_absent', Boolean, default=True)
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.role = ''  # Rôle utilisateur (non stocké en DB)

    @classmethod
    def from_db_row(cls, row: tuple) -> 'UserModel':
        """Crée depuis GET_USER_AUTHENTICATION_QUERY"""
        try:
            user = cls()
            user.id = int(row[0]) if row[0] is not None else None
            user.code = str(row[1]) if row[1] is not None else ""
            user.username = str(row[2]) if row[2] is not None else ""
            user.email = str(row[3]) if row[3] is not None else None
            user.entity = str(row[4]) if row[4] is not None else None
            user.group = str(row[5]) if row[5] is not None else None
            user.url_image = str(row[6]) if row[6] is not None else None
            user.is_absent = bool(row[7]) if len(row) > 7 and row[7] is not None else True
            user.password = str(row[8]) if len(row) > 8 and row[8] is not None else None
            return user
        except (IndexError, ValueError) as e:
            raise ValueError(f"Erreur lors de la création du modèle utilisateur: {e}")

    def to_dict(self) -> Dict[str, Any]:
        """Convertit le modèle en dictionnaire."""
        return {
            'id': str(self.id) if self.id is not None else None,
            'code': self.code,
            'username': self.username,
            'email': self.email,
            'entity': self.entity,
            'group': self.group,
            'url_image': self.url_image,
            'is_absent': self.is_absent,
            'role': self.role
        }

class UserClicClac(BaseClicClac):
    __tablename__ = "users"
    __table_args__ = {'schema': 'dbo'}

    id = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String(150), nullable=False, unique=True, index=True)
    password = Column(String(512), nullable=False)  # stocke le hash bcrypt / argon2
    email = Column(String(255), nullable=False, unique=True, index=True)
    entity = Column(String(100), nullable=False)
    supervisor = Column(Integer, ForeignKey('dbo.users.id', ondelete='SET NULL'), nullable=True, index=True)
    url_image = Column(String(512), nullable=True)
    address = Column(Text, nullable=True)
    company = Column(String(255), nullable=True)
    role = Column(String(100), nullable=False, default='user', index=True)
    is_connected = Column(Boolean, default=False, nullable=True, index=True)
    is_enabled = Column(Boolean, default=True, nullable=True, index=True)
    created_at = Column(Date, default=func.now(), nullable=False)
    updated_at = Column(Date, default=func.now(), onupdate=func.now(), nullable=False)
    
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'id': str(self.id) if self.id is not None else None,
            'username': self.username,
            'email': self.email,
            'supervisor': str(self.supervisor) if self.supervisor is not None else None,
            'entity': self.entity,
            'url_image': self.url_image,
            'role': self.role,
            'address': self.address,
            'company': self.company,
            'is_connected': self.is_connected,
            'is_enabled': self.is_enabled,
            'created_at': self.created_at.isoformat() if self.created_at is not None else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at is not None else None
        }
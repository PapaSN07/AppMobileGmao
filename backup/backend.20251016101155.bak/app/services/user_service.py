import logging
from typing import Any
import bcrypt as bcrypt_lib
from sqlalchemy.exc import IntegrityError

from app.core.config import DEFAULT_PASSWORD_PRESTATAIRE
from app.db.sqlalchemy.session import get_temp_session
from app.models.user_model import UserClicClac
from app.schemas.requests.user_request import AddUserRequest, UpdateUserRequest
from app.schemas.responses.user_response import (
    AddUserResponse, GetAllUsersResponse, UpdateUserResponse, DeleteUserResponse, UserResponse
)

logger = logging.getLogger(__name__)

def _to_frontend_user(user: Any) -> UserResponse:
    """Convertit UserClicClac en UserResponse pour le frontend."""
    return UserResponse(
        id=str(user.id) if user.id is not None else None,
        username=user.username,
        email=user.email,
        role=user.role,
        supervisor=str(user.supervisor) if user.supervisor is not None else None,
        url_image=user.url_image,
        is_connected=user.is_connected,
        is_enabled=user.is_enabled,
        created_at=user.created_at.isoformat() if user.created_at is not None else None,
        updated_at=user.updated_at.isoformat() if user.updated_at is not None else None,
        address=user.address,
        company=user.company
    )

def get_all_users(supervisor_id: int) -> GetAllUsersResponse:
    """
    Récupère tous les utilisateurs depuis la DB temporaire MSSQL (ClicClac).
    """
    try:
        with get_temp_session() as session:
            users = session.query(UserClicClac).filter(UserClicClac.supervisor == supervisor_id).all()
            users_data = [_to_frontend_user(user) for user in users]
            
            return GetAllUsersResponse(
                success=True,
                message="Utilisateurs récupérés avec succès.",
                data=users_data,
                count=len(users_data)
            )
    except Exception as e:
        logger.error(f"❌ Erreur lors de la récupération des utilisateurs: {e}")
        return GetAllUsersResponse(
            success=False,
            message="Erreur interne lors de la récupération.",
            data=[],
            count=0,
            error_code="INTERNAL_ERROR"
        )

def update_user(user_id: int, update_data: UpdateUserRequest) -> UpdateUserResponse:
    """
    Met à jour un utilisateur dans la DB temporaire MSSQL (ClicClac).
    """
    try:
        with get_temp_session() as session:
            user = session.query(UserClicClac).filter(UserClicClac.id == user_id).first()
            
            if not user:
                return UpdateUserResponse(
                    success=False,
                    message="Utilisateur introuvable.",
                    error_code="USER_NOT_FOUND"
                )
            
            # Mettre à jour seulement les champs fournis
            for field, value in update_data.model_dump(exclude_unset=True).items():
                if hasattr(user, field):
                    setattr(user, field, value)
            
            session.commit()
            
            logger.info(f"Utilisateur {user.username} mis à jour avec succès.")
            
            return UpdateUserResponse(
                success=True,
                message="Utilisateur mis à jour avec succès.",
                data=_to_frontend_user(user)
            )
    except IntegrityError as e:
        logger.error(f"Erreur d'intégrité DB: {e}")
        return UpdateUserResponse(
            success=False,
            message="Erreur de contrainte (ex. : unicité violée).",
            error_code="DB_INTEGRITY_ERROR"
        )
    except Exception as e:
        logger.error(f"❌ Erreur lors de la mise à jour de l'utilisateur: {e}")
        return UpdateUserResponse(
            success=False,
            message="Erreur interne lors de la mise à jour.",
            error_code="INTERNAL_ERROR"
        )

def delete_user(user_id: int) -> DeleteUserResponse:
    """
    Supprime un utilisateur dans la DB temporaire MSSQL (ClicClac).
    """
    try:
        with get_temp_session() as session:
            user = session.query(UserClicClac).filter(UserClicClac.id == user_id).first()
            
            if not user:
                return DeleteUserResponse(
                    success=False,
                    message="Utilisateur introuvable.",
                    error_code="USER_NOT_FOUND"
                )
            
            session.delete(user)
            session.commit()
            
            logger.info(f"Utilisateur {user.username} supprimé avec succès.")
            
            return DeleteUserResponse(
                success=True,
                message="Utilisateur supprimé avec succès."
            )
    except Exception as e:
        logger.error(f"❌ Erreur lors de la suppression de l'utilisateur: {e}")
        return DeleteUserResponse(
            success=False,
            message="Erreur interne lors de la suppression.",
            error_code="INTERNAL_ERROR"
        )

def add_user(user_data: AddUserRequest) -> AddUserResponse:
    """
    Ajoute un nouvel utilisateur dans la DB temporaire MSSQL (ClicClac).
    Utilise un mot de passe par défaut pour les prestataires (à changer plus tard).
    Hache le mot de passe avec bcrypt et vérifie l'unicité.
    """
    try:
        # ✅ CORRECTION FINALE: Tronquer à 72 octets AVANT tout traitement
        default_password = DEFAULT_PASSWORD_PRESTATAIRE
        
        hashed_password = bcrypt_lib.hashpw(
            default_password.encode('utf-8'), 
            bcrypt_lib.gensalt()
        ).decode('utf-8')
        
        # Utiliser la session temporaire MSSQL
        with get_temp_session() as session:
            # Vérifier si l'utilisateur existe déjà (par username ou email)
            existing_user = session.query(UserClicClac).filter(
                (UserClicClac.username == user_data.username) | (UserClicClac.email == user_data.email)
            ).first()
            
            if existing_user:
                logger.warning(f"Utilisateur {user_data.username} ou email {user_data.email} existe déjà.")
                return AddUserResponse(
                    success=False,
                    message="L'utilisateur ou l'email est déjà existant.",
                    error_code="USER_EXISTS"
                )
            
            # Créer le nouvel utilisateur
            new_user = UserClicClac(
                username=user_data.username,
                password=hashed_password,
                email=user_data.email,
                supervisor=user_data.supervisor,
                url_image=user_data.url_image,
                address=user_data.address,
                company=user_data.company,
                role=user_data.role,
                is_enabled=user_data.is_enabled
            )
            
            session.add(new_user)
            session.commit()  # Sauvegarder
            
            logger.info(f"Utilisateur {new_user.username} ajouté avec succès dans ClicClac (ID: {new_user.id}).")
            
            return AddUserResponse(
                success=True,
                message="Utilisateur ajouté avec succès (mot de passe par défaut à changer).",
                data=new_user.to_dict()  # Retourner les données de l'utilisateur
            )
    
    except IntegrityError as e:
        logger.error(f"Erreur d'intégrité DB: {e}")
        return AddUserResponse(
            success=False,
            message="Erreur de contrainte (ex. : unicité violée).",
            error_code="DB_INTEGRITY_ERROR"
        )
    except Exception as e:
        logger.error(f"❌ Erreur lors de l'ajout de l'utilisateur: {e}")
        return AddUserResponse(
            success=False,
            message="Erreur interne lors de l'ajout.",
            error_code="INTERNAL_ERROR"
        )
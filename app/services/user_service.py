import logging
from passlib.context import CryptContext
import bcrypt as bcrypt_lib
from sqlalchemy.exc import IntegrityError

from app.core.config import DEFAULT_PASSWORD_PRESTATAIRE
from app.db.sqlalchemy.session import get_temp_session
from app.models.models import UserCliClac
from app.schemas.requests.user_request import AddUserRequest
from app.schemas.responses.user_response import AddUserResponse

logger = logging.getLogger(__name__)

def add_user(user_data: AddUserRequest) -> AddUserResponse:
    """
    Ajoute un nouvel utilisateur dans la DB temporaire MSSQL (CliClac).
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
            existing_user = session.query(UserCliClac).filter(
                (UserCliClac.username == user_data.username) | (UserCliClac.email == user_data.email)
            ).first()
            
            if existing_user:
                logger.warning(f"Utilisateur {user_data.username} ou email {user_data.email} existe déjà.")
                return AddUserResponse(
                    success=False,
                    message="L'utilisateur ou l'email est déjà existant.",
                    error_code="USER_EXISTS"
                )
            
            # Créer le nouvel utilisateur
            new_user = UserCliClac(
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
            
            logger.info(f"Utilisateur {new_user.username} ajouté avec succès dans CliClac (ID: {new_user.id}).")
            
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
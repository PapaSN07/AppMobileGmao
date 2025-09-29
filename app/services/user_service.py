from app.db.sqlalchemy.session import SQLAlchemyQueryExecutor, get_main_session
from app.models.models import UserModel
from app.core.config import CACHE_TTL_SHORT
from app.core.cache import cache
from app.db.requests import (GET_USER_AUTHENTICATION_QUERY, UPDATE_USER_QUERY, GET_USER_CONNECT_QUERY)
import logging
import oracledb

logger = logging.getLogger(__name__)

def authenticate_user(username: str, password: str) -> UserModel | None:
    """
    Authentifie un utilisateur avec son nom d'utilisateur et mot de passe.
    """
    if not username or not password:
        logger.warning("Login ou mot de passe manquant.")
        raise ValueError("Username et mot de passe requis")

    try:
        with get_main_session() as session:
            db = SQLAlchemyQueryExecutor(session)
            
            query = GET_USER_AUTHENTICATION_QUERY
            params = {'username': username, 'password': password}
            results = db.execute_query(query, params=params)
            
            if results:
                user = UserModel.from_db_row(results[0])
                cache_key = f"user_hierarchy_{user.code}"
                cache.set(cache_key, user, CACHE_TTL_SHORT)
                
                logger.info(f"Utilisateur {username} authentifié avec succès.")
                return user
            else:
                logger.warning(f"Échec de l'authentification pour {username}.")
                return None
    except oracledb.DatabaseError as e:
        logger.error(f"❌ Erreur base de données: {e}")
        raise
    except Exception as e:
        logger.error(f"❌ Erreur inattendue: {e}")
        raise

def logout_user(username: str) -> bool:
    """
    Déconnecte un utilisateur en supprimant son cache et en le marquant comme inactif.
    """
    if not username:
        logger.warning("Login manquant pour la déconnexion.")
        return False
    
    user = get_user_connect(username)
    if user:
        # user.is_absent = True  # Marquer comme absent
        success = update_user(user)  # Mettre à jour l'utilisateur
        if success:
            cache_key = f"mobile_eq_{username}_auth"
            cache.delete(cache_key)
            logger.info(f"Utilisateur {username} déconnecté avec succès.")
            return True
        else:
            logger.warning(f"Échec de la mise à jour de l'utilisateur {username}.")
            return False
    else:
        logger.warning(f"Utilisateur {username} introuvable pour la déconnexion.")
        return False

def update_user(user: UserModel) -> bool:
    """
    Met à jour les informations d'un utilisateur.
    
    Args:
        user: Instance de UserModel avec les nouvelles informations
    Returns:
        True si la mise à jour réussit, sinon False
    """
    if not user or not user.id is not None:
        logger.warning("Utilisateur invalide pour la mise à jour.")
        return False
    
    try:
        with get_main_session() as session:
            db = SQLAlchemyQueryExecutor(session)
            
            query = UPDATE_USER_QUERY
            params = {
                'code': user.code,
                'signature': user.username,
                'email': user.email,
                'entity': user.entity,
                'preferred_group': user.group,
                'url_image': user.url_image,
                'is_absent': 1 if user.is_absent is not None else 0,  # Convertir booléen en entier pour Oracle
                'pk': user.id
            }
            db.execute_update(query, params=params)
            logger.info(f"Utilisateur {user.username} mis à jour avec succès.")
            return True
    except oracledb.DatabaseError as e:
        logger.error(f"❌ Erreur base de données lors de la mise à jour: {e}")
        return False
    except Exception as e:
        logger.error(f"❌ Erreur inattendue lors de la mise à jour: {e}")
        return False

def get_user_connect(username: str) -> UserModel | None:
    """
    Récupère un utilisateur connecté à partir de son username ou email.
    
    Args:
        username: Nom d'utilisateur ou email
        
    Returns:
        UserModel si l'utilisateur est trouvé, sinon None
    """
    if not username:
        logger.warning("Login manquant pour la récupération de l'utilisateur.")
        return None
    
    try:
        with get_main_session() as session:
            db = SQLAlchemyQueryExecutor(session)
            
            query = GET_USER_CONNECT_QUERY
            params = {'username': username}
            results = db.execute_query(query, params=params)
            
            if results:
                user = UserModel.from_db_row(results[0])
                logger.info(f"Utilisateur {username} récupéré avec succès.")
                return user
            else:
                logger.warning(f"Utilisateur {username} introuvable.")
                return None
    
    except oracledb.DatabaseError as e:
        logger.error(f"❌ Erreur base de données lors de la récupération de l'utilisateur: {e}")
        return None
    except Exception as e:
        logger.error(f"❌ Erreur inattendue lors de la récupération de l'utilisateur: {e}")
        return None
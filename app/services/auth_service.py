from typing import Union
from passlib.hash import bcrypt
from app.db.sqlalchemy.session import SQLAlchemyQueryExecutor, get_main_session, get_temp_session
from app.models.models import UserCliClac, UserModel
from app.core.config import CACHE_TTL_SHORT
from app.core.cache import cache
from app.db.requests import (GET_USER_AUTHENTICATION_QUERY, UPDATE_USER_QUERY, GET_USER_CONNECT_QUERY)
import logging
import oracledb

logger = logging.getLogger(__name__)

def authenticate_user(username: str, password: str) -> Union[UserModel, UserCliClac] | None:
    """
    Authentifie un utilisateur avec son nom d'utilisateur et mot de passe.
    Vérifie d'abord la base temporaire (CliClac, MSSQL) via UserCliClac,
    puis la base principale (Coswin, Oracle) via UserModel si non trouvé.
    """
    if not username or not password:
        logger.warning("Login ou mot de passe manquant.")
        raise ValueError("Username et mot de passe requis")
    
    # Validation supplémentaire : vérifier la longueur du mot de passe (limite bcrypt)
    if len(password.encode('utf-8')) > 72:
        logger.warning(f"Mot de passe trop long ({len(password.encode('utf-8'))} octets), troncature à 72 octets.")
        password = password[:72]  # Tronquer à 72 octets (limite bcrypt)
    
    try:
        # 1) Vérifier d'abord dans la base temporaire (ClicClac)
        with get_temp_session() as session:
            try:
                # Hacher le mot de passe pour la comparaison (bcrypt comme indiqué dans le modèle)
                hashed_password = bcrypt.hash(password)
            except Exception as hash_error:
                logger.error(f"Erreur lors du hachage bcrypt: {hash_error}")
                # Fallback : utiliser une comparaison simple si hachage échoue (non recommandé en prod)
                hashed_password = password  # ⚠️ À remplacer par une méthode sécurisée
            
            user_temp = session.query(UserCliClac).filter_by(
                username=username, 
                password=hashed_password
            ).first()
            
            if user_temp:
                cache_key = f"user_hierarchy_{user_temp.id}"
                cache.set(cache_key, user_temp, CACHE_TTL_SHORT)

                logger.info(f"Utilisateur {username} authentifié avec succès dans CliClac.")
                return user_temp  # Retourner UserClicClac
        
        # 2) Si non trouvé dans ClicClac, vérifier dans la base principale (Coswin)
        with get_main_session() as session:
            db = SQLAlchemyQueryExecutor(session)
            
            query = GET_USER_AUTHENTICATION_QUERY
            params = {'username': username, 'password': password}
            results = db.execute_query(query, params=params)
            
            if results:
                user_main = UserModel.from_db_row(results[0])
                cache_key = f"user_hierarchy_{user_main.code}"
                cache.set(cache_key, user_main, CACHE_TTL_SHORT)
                
                logger.info(f"Utilisateur {username} authentifié avec succès dans Coswin.")
                return user_main  # Retourner UserModel
            else:
                logger.warning(f"Échec de l'authentification pour {username} dans les deux bases.")
                return None
                
    except oracledb.DatabaseError as e:
        logger.error(f"❌ Erreur base de données principale: {e}")
        raise
    except Exception as e:
        logger.error(f"❌ Erreur inattendue: {e}")
        raise

def logout_user(username: str) -> bool:
    """
    Déconnecte un utilisateur en supprimant son cache et en le marquant comme inactif.
    Vérifie d'abord CliClac, puis Coswin.
    """
    if not username:
        logger.warning("Login manquant pour la déconnexion.")
        return False
    
    user = get_user_connect(username)
    
    if user:
        # Marquer comme absent (logique commune)
        if isinstance(user, UserCliClac):
            setattr(user, 'is_connected', False)
        elif isinstance(user, UserModel):
            setattr(user, 'is_absent', True)

        success = update_user(user)  # Mettre à jour dans la DB appropriée
        
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

def update_user(user: Union[UserModel, UserCliClac]) -> bool:
    """
    Met à jour les informations d'un utilisateur dans la DB appropriée.
    
    Args:
        user: Instance de UserModel ou UserCliClac avec les nouvelles informations
    Returns:
        True si la mise à jour réussit, sinon False
    """
    if not user or not user.id is not None:
        logger.warning("Utilisateur invalide pour la mise à jour.")
        return False
    
    try:
        if isinstance(user, UserCliClac):
            # Mise à jour dans CliClac (MSSQL) via SQLAlchemy
            with get_temp_session() as session:
                session.merge(user)
                session.commit()
                logger.info(f"Utilisateur CliClac {user.username} mis à jour avec succès.")
                return True
        
        elif isinstance(user, UserModel):
            # Mise à jour dans Coswin (Oracle) via requête brute
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
                logger.info(f"Utilisateur Coswin {user.username} mis à jour avec succès.")
                return True
        else:
            logger.error("Type d'utilisateur non supporté pour la mise à jour.")
            return False
    except oracledb.DatabaseError as e:
        logger.error(f"❌ Erreur base de données principale: {e}")
        return False
    except Exception as e:
        logger.error(f"❌ Erreur inattendue lors de la mise à jour: {e}")
        return False

def get_user_connect(username: str) -> Union[UserModel, UserCliClac] | None:
    """
    Récupère un utilisateur connecté à partir de son username ou email.
    Vérifie d'abord CliClac, puis Coswin.
    
    Args:
        username: Nom d'utilisateur ou email
        
    Returns:
        UserCliClac ou UserModel si l'utilisateur est trouvé, sinon None
    """
    if not username:
        logger.warning("Login manquant pour la récupération de l'utilisateur.")
        return None
    
    try:
        # 1) Vérifier d'abord dans CliClac (MSSQL)
        with get_temp_session() as session:
            user_temp = session.query(UserCliClac).filter(
                (UserCliClac.username == username) | (UserCliClac.email == username)
            ).first()
            
            if user_temp:
                logger.info(f"Utilisateur {username} récupéré avec succès dans CliClac.")
                return user_temp  # Retourner UserCliClac
        
        # 2) Si non trouvé dans CliClac, vérifier dans Coswin (Oracle)
        with get_main_session() as session:
            db = SQLAlchemyQueryExecutor(session)
            
            query = GET_USER_CONNECT_QUERY
            params = {'username': username}
            results = db.execute_query(query, params=params)
            
            if results:
                user_main = UserModel.from_db_row(results[0])
                logger.info(f"Utilisateur {username} récupéré avec succès dans Coswin.")
                return user_main  # Retourner UserModel
            else:
                logger.warning(f"Utilisateur {username} introuvable dans les deux bases.")
                return None
    
    except oracledb.DatabaseError as e:
        logger.error(f"❌ Erreur base de données principale: {e}")
        return None
    except Exception as e:
        logger.error(f"❌ Erreur inattendue lors de la récupération de l'utilisateur: {e}")
        return None
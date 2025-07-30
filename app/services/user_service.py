from app.db.database import get_database_connection
from app.models.models import UserModel
from app.core.config import CACHE_TTL_LONG
from app.core.cache import cache
import logging
import oracledb

logger = logging.getLogger(__name__)

def authenticate_user(login: str, password: str) -> UserModel:
    """
    Authentifie un utilisateur avec son nom d'utilisateur et mot de passe.
    
    Args:
        login: Nom d'utilisateur ou email
        password: Mot de passe
        
    Returns:
        UserModel si l'authentification réussit, sinon False
    """
    # Validation des paramètres d'entrée
    if not login or not password:
        logger.warning("Login ou mot de passe manquant.")
        return False
    
    # Cache key
    cache_key = f"mobile_eq_{login}_auth"

    cached = cache.get_data_only(cache_key)
    if cached:
        return cached
    
    # Query de base avec conditions
    base_query = """
    SELECT 
        pk_coswin_user, 
        cwcu_code, 
        cwcu_signature, 
        cwcu_email, 
        cwcu_entity, 
        cwcu_preferred_group, 
        cwcu_url_image,
        cwcu_is_absent, 
        cwcu_password
    FROM coswin.coswin_user
    WHERE 1=1
    """
    
    params = {}
    
    # Ajouter les conditions de filtrage
    if login:
        base_query += " AND (cwcu_signature = :login OR cwcu_email = :login)"
        params['login'] = login

    if password:
        base_query += " AND cwcu_password = :password"
        params['password'] = password
    
    # Vérifier les utilisateurs actifs (cwcu_is_absent = 0 pour Oracle NUMBER)
    base_query += " AND cwcu_is_absent = 0"
    
    # Ajouter la limitation à la fin
    base_query += " AND ROWNUM <= 1"
    
    try:
        with get_database_connection() as db:
            results = db.execute_query(base_query, params=params)
            
            if results:
                if len(results[0]) < 9:  # Nous avons 9 colonnes
                    logger.warning("Données utilisateur incomplètes.")
                    return False
                
                user = UserModel.from_db_row(results[0])

                # Marquer l'utilisateur comme absent
                user.is_absent = False
                update_user(user)  # Mettre à jour l'utilisateur pour marquer comme absent

                # Mettre en cache le résultat
                cache.set(cache_key, user, CACHE_TTL_LONG)
                logger.info(f"Utilisateur {login} authentifié avec succès.")
                return user
            else:
                logger.warning(f"Échec de l'authentification pour {login}.")
                return False
    
    except oracledb.DatabaseError as e:
        logger.error(f"❌ Erreur base de données: {e}")
        return False
    except Exception as e:
        logger.error(f"❌ Erreur inattendue: {e}")
        return False

def logout_user(login: str) -> bool:
    """
    Déconnecte un utilisateur en supprimant son cache et en le marquant comme inactif.
    """
    if not login:
        logger.warning("Login manquant pour la déconnexion.")
        return False
    
    user = get_user_connect(login)
    if user:
        user.is_absent = True  # Marquer comme absent
        update_user(user)  # Mettre à jour l'utilisateur
        cache_key = f"mobile_eq_{login}_auth"
        cache.delete(cache_key)
        logger.info(f"Utilisateur {login} déconnecté avec succès.")
        return True
    else:
        logger.warning(f"Utilisateur {login} introuvable pour la déconnexion.")
        return False

def update_user(user: UserModel) -> bool:
    """
    Met à jour les informations d'un utilisateur.
    
    Args:
        user: Instance de UserModel avec les nouvelles informations
    Returns:
        True si la mise à jour réussit, sinon False
    """
    if not user or not user.id:
        logger.warning("Utilisateur invalide pour la mise à jour.")
        return False
    
    try:
        with get_database_connection() as db:
            query = """
            UPDATE coswin.coswin_user
            SET 
                cwcu_code = :code,
                cwcu_signature = :signature,
                cwcu_email = :email,
                cwcu_entity = :entity,
                cwcu_preferred_group = :preferred_group,
                cwcu_url_image = :url_image,
                cwcu_is_absent = :is_absent
            WHERE pk_coswin_user = :pk
            """
            params = {
                'code': user.code,
                'signature': user.username,
                'email': user.email,
                'entity': user.entity,
                'preferred_group': user.group,
                'url_image': user.url_image,
                'is_absent': 1 if user.is_absent else 0,  # Convertir booléen en entier pour Oracle
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

def get_user_connect(login: str) -> UserModel:
    """
    Récupère un utilisateur connecté à partir de son login ou email.
    
    Args:
        login: Nom d'utilisateur ou email
        
    Returns:
        UserModel si l'utilisateur est trouvé, sinon None
    """
    if not login:
        logger.warning("Login manquant pour la récupération de l'utilisateur.")
        return None
    
    try:
        with get_database_connection() as db:
            query = """
            SELECT 
                pk_coswin_user, 
                cwcu_code, 
                cwcu_signature, 
                cwcu_email, 
                cwcu_entity, 
                cwcu_preferred_group, 
                cwcu_url_image,
                cwcu_is_absent
            FROM coswin.coswin_user
            WHERE (cwcu_signature = :login OR cwcu_email = :login)
            AND ROWNUM <= 1
            """
            params = {'login': login}
            results = db.execute_query(query, params=params)
            
            if results:
                user = UserModel.from_db_row(results[0])
                logger.info(f"Utilisateur {login} récupéré avec succès.")
                return user
            else:
                logger.warning(f"Utilisateur {login} introuvable.")
                return None
    except oracledb.DatabaseError as e:
        logger.error(f"❌ Erreur base de données lors de la récupération de l'utilisateur: {e}")
        return None
    except Exception as e:
        logger.error(f"❌ Erreur inattendue lors de la récupération de l'utilisateur: {e}")
        return None
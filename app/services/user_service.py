from app.db.database import get_database_connection
from app.models.models import UserModel
from app.core.config import CACHE_TTL_LONG
from app.core.cache import cache
import logging
import oracledb

logger = logging.getLogger(__name__)

def authenticate_user(login: str, password: str) -> bool:
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
    
    # Query de base avec conditions - CORRECTION ICI
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
    Déconnecte un utilisateur en supprimant son cache.
    
    Args:
        login: Nom d'utilisateur ou email
    Returns:
        True si la déconnexion réussit, sinon False
    """
    if not login:
        logger.warning("Login manquant pour la déconnexion.")
        return False
    
    cache_key = f"mobile_eq_{login}_auth"
    return cache.delete(cache_key)
import redis
import json
import logging
from typing import Optional, Any, Dict, List, cast
from datetime import datetime
from app.core.config import REDIS_HOST, REDIS_PORT, REDIS_DB, CACHE_TTL_MEDIUM, CACHE_TTL_LONG

# Configuration du logging
logger = logging.getLogger(__name__)

class RedisCache:
    """
    Gestionnaire de cache Redis pour l'application FastAPI.
    Gère la mise en cache des données d'équipements avec fallback gracieux.
    """
    
    def __init__(self):
        """Initialise la connexion Redis avec gestion d'erreurs"""
        try:
            self.redis_client = redis.Redis(
                host=REDIS_HOST,
                port=REDIS_PORT,
                db=REDIS_DB,
                decode_responses=True,
                socket_connect_timeout=5,
                socket_timeout=5,
                retry_on_timeout=True,
                max_connections=20
            )
            
            # Test de connexion
            self.redis_client.ping()
            self.is_available = True
            logger.info(f"✅ Redis connecté: {REDIS_HOST}:{REDIS_PORT}")
            
        except redis.ConnectionError as e:
            logger.warning(f"⚠️ Redis non disponible: {e}. L'application fonctionnera sans cache.")
            self.redis_client = None
            self.is_available = False
            
        except Exception as e:
            logger.error(f"❌ Erreur Redis inattendue: {e}")
            self.redis_client = None
            self.is_available = False

    def _create_key(self, prefix: str, identifier: str = "", **kwargs) -> str:
        """
        Crée une clé de cache standardisée.
        
        Args:
            prefix: Préfixe de la clé (ex: 'equipment', 'zones')
            identifier: Identifiant unique (optionnel)
            **kwargs: Paramètres additionnels pour la clé
            
        Returns:
            Clé de cache formatée
        """
        key_parts = [prefix]
        
        if identifier:
            key_parts.append(identifier)
            
        # Ajouter les paramètres triés pour consistance
        if kwargs:
            params_str = "_".join([f"{k}:{v}" for k, v in sorted(kwargs.items()) if v is not None])
            if params_str:
                key_parts.append(params_str)
        
        return ":".join(key_parts)

    def get(self, key: str) -> Optional[Any]:
        """
        Récupère une valeur du cache.
        
        Args:
            key: Clé de cache
            
        Returns:
            Valeur désérialisée ou None si pas trouvée/erreur
        """
        if not self.is_available or self.redis_client is None:
            return None
        
        try:
            value = self.redis_client.get(key)
            if value and isinstance(value, (str, bytes, bytearray)):
                return json.loads(value)
            return None
            
        except json.JSONDecodeError as e:
            logger.error(f"❌ Erreur de désérialisation cache {key}: {e}")
            # Supprimer la clé corrompue
            self.delete(key)
            return None
            
        except Exception as e:
            logger.error(f"❌ Erreur lecture cache {key}: {e}")
            return None

    def set(self, key: str, value: Any, ttl: int = CACHE_TTL_MEDIUM) -> bool:
        """
        Stocke une valeur dans le cache.
        
        Args:
            key: Clé de cache
            value: Valeur à stocker
            ttl: Durée de vie en secondes
            
        Returns:
            True si succès, False sinon
        """
        if not self.is_available or self.redis_client is None:
            return False
        
        try:
            # Ajouter timestamp pour debug
            cache_data = {
                "data": value,
                "cached_at": datetime.now().isoformat(),
                "ttl": ttl
            }
            
            serialized_value = json.dumps(cache_data, ensure_ascii=False, default=str)
            result = self.redis_client.setex(key, ttl, serialized_value)
            
            if result:
                logger.debug(f"✅ Cache mis à jour: {key} (TTL: {ttl}s)")
            return bool(result)
            
        except Exception as e:
            logger.error(f"❌ Erreur écriture cache {key}: {e}")
            return False

    def get_data_only(self, key: str) -> Optional[Any]:
        """
        Récupère uniquement les données du cache (sans métadonnées).
        
        Args:
            key: Clé de cache
            
        Returns:
            Données ou None
        """
        cached = self.get(key)
        if cached and isinstance(cached, dict) and "data" in cached:
            return cached["data"]
        return cached

    def delete(self, key: str) -> bool:
        """
        Supprime une clé du cache.
        
        Args:
            key: Clé à supprimer
            
        Returns:
            True si succès, False sinon
        """
        if not self.is_available or self.redis_client is None:
            return False
        
        try:
            result = self.redis_client.delete(key)
            if result:
                logger.debug(f"🗑️ Cache supprimé: {key}")
            return bool(result)
            
        except Exception as e:
            logger.error(f"❌ Erreur suppression cache {key}: {e}")
            return False

    def clear_pattern(self, pattern: str) -> int:  # ❌ RETIRE async
        """
        Supprime toutes les clés correspondant à un pattern.
        
        Args:
            pattern: Pattern de recherche (ex: 'equipment:*')
            
        Returns:
            Nombre de clés supprimées
        """
        if not self.is_available or self.redis_client is None:
            return 0
        
        try:
            keys = self.redis_client.keys(pattern)
            if keys:
                deleted = self.redis_client.delete(*keys)  # type: ignore
                logger.info(f"🧹 {deleted} clés supprimées pour pattern: {pattern}")
                return int(deleted) # type: ignore
            return 0
            
        except Exception as e:
            logger.error(f"❌ Erreur suppression pattern {pattern}: {e}")
            return 0

    def clear_all(self) -> bool:
        """
        Vide tout le cache de la base de données Redis courante.
        
        Returns:
            True si succès, False sinon
        """
        if not self.is_available or self.redis_client is None:
            return False
        
        try:
            self.redis_client.flushdb()
            logger.info("🧹 Cache entièrement vidé")
            return True
            
        except Exception as e:
            logger.error(f"❌ Erreur vidage cache: {e}")
            return False

    def get_cache_info(self) -> Dict[str, Any]:
        """
        Récupère les informations sur le cache.
        
        Returns:
            Dictionnaire avec les infos du cache
        """
        if not self.is_available or self.redis_client is None:
            return {
                "status": "unavailable",
                "keys_count": 0,
                "memory_usage": "unknown"
            }
        
        try:
            info = self.redis_client.info()
            keys_count = self.redis_client.dbsize()
            
            return {
                "status": "available",
                "keys_count": keys_count,
                "memory_usage": info.get('used_memory_human', 'unknown') if isinstance(info, dict) else 'unknown',
                "connected_clients": info.get('connected_clients', 0) if isinstance(info, dict) else 0,
                "total_commands_processed": info.get('total_commands_processed', 0) if isinstance(info, dict) else 0
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur info cache: {e}")
            return {"status": "error", "error": str(e)}

    def exists(self, key: str) -> bool:
        """
        Vérifie si une clé existe dans le cache.
        
        Args:
            key: Clé à vérifier
            
        Returns:
            True si existe, False sinon
        """
        if not self.is_available or self.redis_client is None:
            return False
        
        try:
            return bool(self.redis_client.exists(key))
        except Exception as e:
            logger.error(f"❌ Erreur vérification existence {key}: {e}")
            return False

    def get_ttl(self, key: str) -> int:
        """
        Récupère le TTL d'une clé.
        
        Args:
            key: Clé à vérifier
            
        Returns:
            TTL en secondes (-1 si pas de TTL, -2 si clé n'existe pas)
        """
        if not self.is_available or self.redis_client is None:
            return -2
        
        try:
            return cast(int, self.redis_client.ttl(key))
        except Exception as e:
            logger.error(f"❌ Erreur TTL {key}: {e}")
            return -2

    def extend_ttl(self, key: str, additional_seconds: int) -> bool:
        """
        Étend le TTL d'une clé existante.
        
        Args:
            key: Clé à modifier
            additional_seconds: Secondes à ajouter
            
        Returns:
            True si succès, False sinon
        """
        if not self.is_available or self.redis_client is None:
            return False
        
        try:
            current_ttl = self.get_ttl(key)
            if current_ttl > 0:
                new_ttl = current_ttl + additional_seconds
                return bool(self.redis_client.expire(key, new_ttl))
            return False
            
        except Exception as e:
            logger.error(f"❌ Erreur extension TTL {key}: {e}")
            return False

# Instance globale du cache
cache = RedisCache()

# Fonctions helper spécifiques au projet
def cache_equipment_list(data: List[Dict], filters: Dict[str, Any] | None = None, ttl: int = CACHE_TTL_MEDIUM) -> bool:
    """
    Met en cache une liste d'équipements avec filtres.
    
    Args:
        data: Liste des équipements
        filters: Filtres appliqués
        ttl: Durée de vie du cache
        
    Returns:
        True si mis en cache avec succès
    """
    key = cache._create_key("equipment_list", **filters or {})
    return cache.set(key, data, ttl)

def get_cached_equipment_list(filters: Dict[str, Any] | None = None) -> Optional[List[Dict]]:
    """
    Récupère une liste d'équipements mise en cache.
    
    Args:
        filters: Filtres de recherche
        
    Returns:
        Liste d'équipements ou None
    """
    key = cache._create_key("equipment_list", **filters or {})
    return cache.get_data_only(key)

def cache_zones_list(zones: List[str], ttl: int = CACHE_TTL_LONG) -> bool:
    """Met en cache la liste des zones."""
    return cache.set("zones_list", zones, ttl)

def get_cached_zones_list() -> Optional[List[str]]:
    """Récupère la liste des zones en cache."""
    return cache.get_data_only("zones_list")

def cache_familles_list(familles: List[str], ttl: int = CACHE_TTL_LONG) -> bool:
    """Met en cache la liste des familles."""
    return cache.set("familles_list", familles, ttl)

def get_cached_familles_list() -> Optional[List[str]]:
    """Récupère la liste des familles en cache."""
    return cache.get_data_only("familles_list")

def cache_entities_list(entities: List[str], ttl: int = CACHE_TTL_LONG) -> bool:
    """Met en cache la liste des entités."""
    return cache.set("entities_list", entities, ttl)

def get_cached_entities_list() -> Optional[List[str]]:
    """Récupère la liste des entités en cache."""
    return cache.get_data_only("entities_list")

def invalidate_equipment_cache():
    """Invalide tout le cache des équipements."""
    patterns = ["equipment:*", "equipment_list:*", "zones_list", "familles_list", "entities_list"]
    total_deleted = 0
    for pattern in patterns:
        total_deleted += cache.clear_pattern(pattern)
    
    logger.info(f"🧹 Cache équipements invalidé: {total_deleted} clés supprimées")
    return total_deleted

async def get_cache_stats() -> Dict[str, Any]:
    """
    Récupère les statistiques détaillées du cache.
    
    Returns:
        Dictionnaire avec les statistiques
    """
    stats = cache.get_cache_info()
    
    # Ajouter des statistiques spécifiques au projet
    if cache.is_available and cache.redis_client is not None:
        try:
            equipment_keys_result = await cache.redis_client.keys("equipment*")
            equipment_keys = len(equipment_keys_result) if equipment_keys_result else 0
            zones_cached = cache.exists("zones_list")
            familles_cached = cache.exists("familles_list")
            entities_cached = cache.exists("entities_list")
            
            stats.update({
                "equipment_cache_keys": equipment_keys,
                "reference_lists_cached": {
                    "zones": zones_cached,
                    "familles": familles_cached,
                    "entities": entities_cached
                }
            })
        except Exception as e:
            logger.error(f"❌ Erreur stats spécifiques: {e}")
    
    return stats

# Décorateur pour la mise en cache automatique
def cached(ttl: int = CACHE_TTL_MEDIUM, key_prefix: str = "auto"):
    """
    Décorateur pour mise en cache automatique des fonctions.
    
    Args:
        ttl: Durée de vie du cache
        key_prefix: Préfixe de la clé de cache
    """
    def decorator(func):
        def wrapper(*args, **kwargs):
            # Créer une clé basée sur le nom de la fonction et les arguments
            key_parts = [key_prefix, func.__name__]
            if args:
                key_parts.append(str(hash(str(args))))
            if kwargs:
                key_parts.append(str(hash(str(sorted(kwargs.items())))))
            
            cache_key = ":".join(key_parts)
            
            # Vérifier le cache
            cached_result = cache.get_data_only(cache_key)
            if cached_result is not None:
                logger.debug(f"📋 Cache hit: {cache_key}")
                return cached_result
            
            # Exécuter la fonction et mettre en cache
            result = func(*args, **kwargs)
            cache.set(cache_key, result, ttl)
            logger.debug(f"💾 Cache miss, stored: {cache_key}")
            
            return result
        return wrapper
    return decorator

if __name__ == "__main__":
    # Tests de base
    print("🧪 Test du cache Redis...")
    
    print(f"Redis disponible: {cache.is_available}")
    
    if cache.is_available:
        # Test CRUD
        test_key = "test_key"
        test_data = {"message": "Hello Redis!", "timestamp": datetime.now().isoformat()}
        
        print(f"✅ Set: {cache.set(test_key, test_data, 60)}")
        print(f"✅ Get: {cache.get_data_only(test_key)}")
        print(f"✅ Exists: {cache.exists(test_key)}")
        print(f"✅ TTL: {cache.get_ttl(test_key)}s")
        print(f"✅ Delete: {cache.delete(test_key)}")
        
        # Stats
        print(f"📊 Stats: {cache.get_cache_info()}")
    
    print("✅ Tests terminés")
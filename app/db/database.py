import oracledb
from typing import Dict, Any, List, Optional
from dataclasses import dataclass
from app.core.config import (
    DB_USERNAME, DB_PASSWORD, DB_HOST, DB_SERVICE_NAME, TEMP_DB_PORT,
    TEMP_DB_USERNAME, TEMP_DB_PASSWORD, TEMP_DB_HOST, TEMP_DB_SERVICE_NAME,
    DB_PORT, MAX_LIMIT, DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE
)

@dataclass
class PaginationParams:
    """Paramètres de pagination"""
    page: int = 1
    limit: int = DEFAULT_PAGE_SIZE
    
    def __post_init__(self):
        if self.page < 1:
            raise ValueError("Le numéro de page doit être supérieur à 0")
        if self.limit < 1 or self.limit > MAX_PAGE_SIZE:
            raise ValueError(f"La limite doit être entre 1 et {MAX_PAGE_SIZE}")

@dataclass 
class PaginationResult:
    """Résultat de pagination"""
    data: List[tuple]
    total_count: int
    page: int
    page_size: int
    total_pages: int
    has_next: bool
    has_prev: bool

class OracleDatabase:
    """Classe pour gérer les connexions et requêtes Oracle"""
    
    def __init__(self, db_type: str = "main"):
        """Initialise la connexion à la base de données Oracle"""
        self.connection = None
        self.db_type = db_type  # "main" ou "temp"
    
    def connect(self):
        """Établit la connexion à la base de données (principale ou temporaire selon db_type)"""
        try:
            if self.db_type == "main":
                connection_string = f"{DB_USERNAME}/{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_SERVICE_NAME}"
            elif self.db_type == "temp":
                connection_string = f"{TEMP_DB_USERNAME}/{TEMP_DB_PASSWORD}@{TEMP_DB_HOST}:{TEMP_DB_PORT}/{TEMP_DB_SERVICE_NAME}"
            else:
                raise ValueError("Type de DB invalide")
            
            self.connection = oracledb.connect(connection_string)
            print(f"✅ Connexion réussie à Oracle ({self.db_type}): {connection_string}")
        except oracledb.DatabaseError as e:
            print(f"❌ Erreur de connexion Oracle ({self.db_type}): {e}")
            self.connection = None
            raise ConnectionError(f"Impossible de se connecter à la base de données: {e}")
        except Exception as e:
            print(f"❌ Erreur inattendue: {e}")
            self.connection = None
            raise

    def is_connected(self) -> bool:
        """Vérifie si la connexion est active"""
        if not self.connection:
            return False
        try:
            # Test simple pour vérifier la connexion
            cursor = self.connection.cursor()
            cursor.execute("SELECT 1 FROM DUAL")
            cursor.close()
            return True
        except:
            return False
    
    def execute_query(self, query: str, params: Optional[Dict[str, Any]] = None, limit: Optional[int] = None) -> List[tuple]:
        """
        Exécute une requête SQL avec paramètres optionnels et limitation.
        """
        if not self.connection:
            raise ConnectionError("Pas de connexion à la base de données")
        
        # Validation de la limite
        if limit is not None:
            if limit < 1 or limit > MAX_LIMIT:
                raise ValueError(f"La limite doit être entre 1 et {MAX_LIMIT}")
        
        cursor = None
        try:
            cursor = self.connection.cursor()
            
            # CORRECTION: Appliquer la limitation différemment
            if limit:
                # Vérifier si la requête contient déjà ROWNUM ou une sous-requête
                if "ROWNUM" in query.upper() or query.strip().startswith("SELECT * FROM ("):
                    # La requête gère déjà la limitation
                    cursor.execute(query, params or {})
                else:
                    # Appliquer ROWNUM pour limiter les résultats
                    limited_query = f"""
                    SELECT * FROM (
                        {query}
                    ) WHERE ROWNUM <= :query_limit
                    """
                    query_params = params.copy() if params else {}
                    query_params['query_limit'] = limit
                    cursor.execute(limited_query, query_params)
            else:
                cursor.execute(query, params or {})
            
            results = cursor.fetchall()
            print(f"📊 Requête exécutée: {len(results)} résultats")
            return results
            
        except oracledb.DatabaseError as e:
            print(f"❌ Erreur SQL: {e}")
            raise
        except Exception as e:
            print(f"❌ Erreur inattendue lors de l'exécution: {e}")
            raise
        finally:
            if cursor:
                cursor.close()
    
    def execute_query_with_pagination(
        self, 
        query: str, 
        params: Optional[Dict[str, Any]] = None, 
        page: int = 1, 
        page_size: int = DEFAULT_PAGE_SIZE
    ) -> PaginationResult:
        """
        Exécute une requête avec pagination Oracle.
        
        Args:
            query: Requête SQL de base
            params: Paramètres de la requête
            page: Numéro de page (commence à 1)
            page_size: Taille de la page
            
        Returns:
            PaginationResult avec données et métadonnées
        """
        if not self.connection:
            raise ConnectionError("Pas de connexion à la base de données")
        
        # Valider les paramètres de pagination
        pagination_params = PaginationParams(page=page, limit=page_size)
        
        cursor = None
        try:
            cursor = self.connection.cursor()
            query_params = params.copy() if params else {}
            
            # 1. Compter le total des résultats
            count_query = f"SELECT COUNT(*) FROM ({query})"
            cursor.execute(count_query, query_params)
            total_count = cursor.fetchone()[0]
            
            # 2. Calculer les métadonnées de pagination
            total_pages = (total_count + page_size - 1) // page_size
            offset = (page - 1) * page_size
            
            # 3. Exécuter la requête paginée avec ROWNUM Oracle
            paginated_query = f"""
            SELECT * FROM (
                SELECT a.*, ROWNUM rnum FROM (
                    {query}
                ) a WHERE ROWNUM <= {offset + page_size}
            ) WHERE rnum > {offset}
            """
            
            cursor.execute(paginated_query, query_params)
            results = cursor.fetchall()
            
            # 4. Créer le résultat de pagination
            pagination_result = PaginationResult(
                data=results,
                total_count=total_count,
                page=page,
                page_size=page_size,
                total_pages=total_pages,
                has_next=page < total_pages,
                has_prev=page > 1
            )
            
            print(f"📄 Page {page}/{total_pages} - {len(results)} résultats sur {total_count} total")
            return pagination_result
            
        except oracledb.DatabaseError as e:
            print(f"❌ Erreur SQL pagination: {e}")
            raise
        except Exception as e:
            print(f"❌ Erreur pagination: {e}")
            raise
        finally:
            if cursor:
                cursor.close()
    
    def execute_count_query(self, query: str, params: Optional[Dict[str, Any]] = None) -> int:
        """
        Exécute une requête de comptage.
        
        Args:
            query: Requête SQL de comptage
            params: Paramètres de la requête
            
        Returns:
            Nombre de résultats
        """
        if not self.connection:
            raise ConnectionError("Pas de connexion à la base de données")
        
        cursor = None
        try:
            cursor = self.connection.cursor()
            cursor.execute(query, params or {})
            result = cursor.fetchone()
            count = result[0] if result else 0
            return count
        except oracledb.DatabaseError as e:
            print(f"❌ Erreur SQL count: {e}")
            raise
        finally:
            if cursor:
                cursor.close()
    
    def execute_update(self, query: str, params: Optional[Dict[str, Any]] = None, commit: bool = True) -> int:
        """
        Exécute une requête UPDATE/INSERT/DELETE.

        Args:
            query: Requête SQL à exécuter
            params: Paramètres nommés pour la requête
            commit: Si True (par défaut) effectue un commit après exécution.
                    Si False, laisse le commit/rollback à l'appelant (utile pour transactions).

        Returns:
            Nombre de lignes affectées

        Raises:
            ConnectionError: Si pas de connexion à la DB
            oracledb.DatabaseError: Pour les erreurs SQL
        """
        if not self.connection:
            raise ConnectionError("Pas de connexion à la base de données")

        cursor = None
        try:
            cursor = self.connection.cursor()
            cursor.execute(query, params or {})
            affected_rows = cursor.rowcount

            if commit:
                # comportement rétrocompatible : commit automatique
                self.connection.commit()
                print(f"📝 Mise à jour exécutée: {affected_rows} ligne(s) affectée(s) (commit effectué)")
            else:
                # pas de commit — caller doit appeler commit_transaction() ou rollback_transaction()
                print(f"📝 Mise à jour exécutée: {affected_rows} ligne(s) affectée(s) (commit différé)")

            return affected_rows

        except oracledb.DatabaseError as e:
            # rollback seulement si on gérait le commit ici
            if commit and self.connection:
                try:
                    self.connection.rollback()
                except Exception:
                    pass
            print(f"❌ Erreur SQL update: {e}")
            raise
        except Exception as e:
            if commit and self.connection:
                try:
                    self.connection.rollback()
                except Exception:
                    pass
            print(f"❌ Erreur inattendue lors de la mise à jour: {e}")
            raise
        finally:
            if cursor:
                cursor.close()
    
    def close_connection(self):
        """Ferme la connexion à la base de données"""
        if self.connection:
            try:
                self.connection.close()
                print("🔌 Connexion Oracle fermée")
            except Exception as e:
                print(f"⚠️ Erreur lors de la fermeture: {e}")
            finally:
                self.connection = None
    
    def __enter__(self):
        """Support pour le gestionnaire de contexte"""
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Ferme automatiquement la connexion"""
        self.close_connection()
        if exc_type:
            print(f"❌ Exception dans le contexte DB: {exc_type.__name__}: {exc_val}")
        return False  # Ne supprime pas l'exception
    
    def begin_transaction(self):
        """Démarre une transaction"""
        if not self.connection:
            raise ConnectionError("Pas de connexion à la base de données")
        # En Oracle avec oracledb, les transactions sont automatiques
        # Cette méthode est pour la compatibilité
        pass
    
    def commit_transaction(self):
        """Valide la transaction"""
        if not self.connection:
            raise ConnectionError("Pas de connexion à la base de données")
        try:
            self.connection.commit()
            print("✅ Transaction validée")
        except oracledb.DatabaseError as e:
            print(f"❌ Erreur commit: {e}")
            raise
    
    def rollback_transaction(self):
        """Annule la transaction"""
        if not self.connection:
            raise ConnectionError("Pas de connexion à la base de données")
        try:
            self.connection.rollback()
            print("🔄 Transaction annulée")
        except oracledb.DatabaseError as e:
            print(f"❌ Erreur rollback: {e}")
            raise

# Créer deux instances globales distinctes
main_db_instance = OracleDatabase(db_type="main")
temp_db_instance = OracleDatabase(db_type="temp")

def get_database_connection() -> OracleDatabase:
    """Factory function pour créer une connexion DB principale"""
    main_db_instance.connect()
    return main_db_instance

def get_database_connection_temp() -> OracleDatabase:
    """Factory function pour créer une connexion DB temporaire"""
    temp_db_instance.connect()
    return temp_db_instance

# Test de connexion mis à jour
def test_connection():
    """Teste la connexion aux deux bases de données"""
    try:
        # Test DB principale
        main_db = get_database_connection()
        print("🔎 Test DB principale...")
        if main_db.is_connected():
            print("✅ Connexion DB principale OK")
            results = main_db.execute_query("SELECT SYSDATE FROM DUAL")
            print(f"📅 Date système (main): {results[0][0]}")
        else:
            print("❌ Connexion DB principale échouée")
        main_db.close_connection()

        # Test DB temporaire
        temp_db = get_database_connection_temp()
        print("🔎 Test DB temporaire...")
        if temp_db.is_connected():
            print("✅ Connexion DB temporaire OK")
            results = temp_db.execute_query("SELECT SYSDATE FROM DUAL")
            print(f"📅 Date système (temp): {results[0][0]}")
        else:
            print("❌ Connexion DB temporaire échouée")
        temp_db.close_connection()

        return True
    except Exception as e:
        print(f"❌ Erreur test connexion: {e}")
        return False

if __name__ == "__main__":
    # Test de base lors de l'exécution directe
    test_connection()
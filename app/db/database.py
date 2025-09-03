import oracledb
from typing import Dict, Any, List, Optional
from dataclasses import dataclass
from app.core.config import (
    DB_USERNAME, DB_PASSWORD, DB_HOST, DB_SERVICE_NAME,
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
    
    def __init__(self):
        """Initialise la connexion à la base de données Oracle"""
        self.connection = None
        self._connect()
    
    def _connect(self):
        """Établit la connexion à la base de données"""
        try:
            # Créer la chaîne de connexion Oracle
            connection_string = f"{DB_USERNAME}/{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_SERVICE_NAME}"
            self.connection = oracledb.connect(connection_string)
            print(f"✅ Connexion réussie à Oracle: {DB_HOST}:{DB_SERVICE_NAME}")
        except oracledb.DatabaseError as e:
            print(f"❌ Erreur de connexion Oracle: {e}")
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
    
    def execute_update(self, query: str, params: Optional[Dict[str, Any]] = None) -> int:
        """
        Exécute une requête UPDATE/INSERT/DELETE.
        
        Args:
            query: Requête SQL à exécuter
            params: Paramètres nommés pour la requête
            
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
            self.connection.commit()  # Important pour Oracle
            
            print(f"📝 Mise à jour exécutée: {affected_rows} ligne(s) affectée(s)")
            return affected_rows
            
        except oracledb.DatabaseError as e:
            if self.connection:
                self.connection.rollback()
            print(f"❌ Erreur SQL update: {e}")
            raise
        except Exception as e:
            if self.connection:
                self.connection.rollback()
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
    
    def execute_insert(self, query: str, params: Optional[Dict[str, Any]] = None) -> Optional[int]:
        """
        Exécute une requête INSERT et retourne l'ID généré.
        
        Args:
            query: Requête SQL INSERT
            params: Paramètres nommés pour la requête
            
        Returns:
            ID généré (si applicable) ou None
        """
        if not self.connection:
            raise ConnectionError("Pas de connexion à la base de données")
        
        cursor = None
        try:
            cursor = self.connection.cursor()
            
            # Pour Oracle, on peut utiliser RETURNING INTO
            if "RETURNING" not in query.upper():
                # Exécuter l'INSERT normal
                cursor.execute(query, params or {})
                affected_rows = cursor.rowcount
                
                if affected_rows > 0:
                    # Essayer de récupérer l'ID avec CURRVAL si on a une séquence
                    try:
                        # Cette approche fonctionne si on utilise une séquence
                        cursor.execute("SELECT LASTVAL FROM DUAL")  # Remplacer par votre méthode
                        result = cursor.fetchone()
                        return result[0] if result else affected_rows
                    except:
                        # Si pas de séquence, retourner le nombre de lignes
                        return affected_rows
                else:
                    return None
            else:
                # Requête avec RETURNING
                cursor.execute(query, params or {})
                result = cursor.fetchone()
                return result[0] if result else None
                
        except oracledb.DatabaseError as e:
            print(f"❌ Erreur SQL insert: {e}")
            raise
        except Exception as e:
            print(f"❌ Erreur inattendue lors de l'insertion: {e}")
            raise
        finally:
            if cursor:
                cursor.close()

# Fonction utilitaire pour créer une connexion
def get_database_connection() -> OracleDatabase:
    """Factory function pour créer une connexion DB"""
    return OracleDatabase()

# Test de connexion
def test_connection():
    """Teste la connexion à la base de données"""
    try:
        with OracleDatabase() as db:
            if db.is_connected():
                print("✅ Test de connexion réussi")
                # Test simple avec DUAL uniquement
                results = db.execute_query("SELECT SYSDATE FROM DUAL")
                print(f"📅 Date système: {results[0][0]}")
                
                # Test optionnel de vérification des tables
                try:
                    # Vérifier que les tables existent
                    table_check = db.execute_query("""
                        SELECT COUNT(*) FROM user_tables 
                        WHERE table_name IN ('T_EQUIPMENT', 'COSWIN_USER', 'CATEGORY')
                    """)
                    tables_count = table_check[0][0] if table_check else 0
                    print(f"📋 Tables trouvées: {tables_count}/3")
                except Exception as table_error:
                    print(f"⚠️ Avertissement tables: {table_error}")
                
                return True
            else:
                print("❌ Test de connexion échoué")
                return False
    except Exception as e:
        print(f"❌ Erreur test connexion: {e}")
        return False

if __name__ == "__main__":
    # Test de base lors de l'exécution directe
    test_connection()
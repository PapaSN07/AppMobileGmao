import os
import sys
import datetime
from pathlib import Path
import urllib.parse

# Régler l'encodage de la console Windows si nécessaire
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

from dotenv import load_dotenv
from sqlalchemy import create_engine, text

# Chemins des fichiers
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent.parent
ENV_FILE = SCRIPT_DIR.parent / ".env.prod"
LOG_FILE = PROJECT_DIR / "rapport_provisionnement.txt"

def log(msg: str):
    """Affiche à l'écran et écrit dans le fichier de rapport"""
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    formatted = f"[{timestamp}] {msg}"
    print(formatted)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(formatted + "\n")

def main():
    # Re-créer le fichier journal
    with open(LOG_FILE, "w", encoding="utf-8") as f:
        f.write("====================================================\n")
        f.write("  RAPPORT DE PROVISIONNEMENT COSWIN_USER DANS ODS\n")
        f.write("====================================================\n\n")

    log("DEBUT du script de provisionnement de coswin_user...")
    
    if not ENV_FILE.exists():
        log(f"ERREUR: Fichier d'environnement introuvable: {ENV_FILE}")
        return

    load_dotenv(ENV_FILE, override=True)
    
    host = os.getenv("DB_HOST", "127.0.0.1")
    port = os.getenv("DB_PORT", "1433")
    dbname = os.getenv("DB_NAME", "gmao_backend")
    user = os.getenv("DB_USERNAME", "sa")
    password = os.getenv("DB_PASSWORD", "")

    log(f"Connexion a la base de donnees SQL Server: Host={host}:{port}, DB={dbname}, User={user}")

    try:
        dsn = f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={host},{port};DATABASE={dbname};UID={user};PWD={password};TrustServerCertificate=yes;Encrypt=no"
        url = "mssql+pyodbc:///?odbc_connect=" + urllib.parse.quote_plus(dsn)
        engine = create_engine(url, echo=False)

        with engine.begin() as conn:
            log("OK: Connexion a la base de donnees reussie !")

            # 1. Vérification / Création de la table coswin_user
            log("Verification de l'existence de la table dbo.coswin_user...")
            create_table_sql = """
            IF OBJECT_ID('dbo.coswin_user', 'U') IS NULL
            BEGIN
                CREATE TABLE dbo.coswin_user (
                    pk_coswin_user INT IDENTITY(1,1) NOT NULL,
                    cwcu_code VARCHAR(50) NOT NULL,
                    cwcu_signature VARCHAR(255) NOT NULL,
                    cwcu_password VARCHAR(255) NULL,
                    cwcu_email VARCHAR(255) NULL,
                    cwcu_entity VARCHAR(50) NULL,
                    cwcu_preferred_group VARCHAR(50) NULL,
                    cwcu_url_image VARCHAR(500) NULL,
                    cwcu_is_absent INT DEFAULT 0,
                    CONSTRAINT PK_coswin_user PRIMARY KEY (pk_coswin_user),
                    CONSTRAINT UQ_coswin_user_cwcu_code UNIQUE (cwcu_code)
                );
            END
            """
            conn.execute(text(create_table_sql))
            log("OK: Table dbo.coswin_user verifiee / creee avec succes.")

            # 2. Utilisateurs de référence à provisionner
            users_to_provision = [
                {
                    "code": "5286",
                    "signature": "ERIC DASYLVA CARDOZO",
                    "email": "eric.cardozo@electricite.sn",
                    "entity": "SENELEC",
                    "group": "ADMIN"
                },
                {
                    "code": "6732",
                    "signature": "TECHNICIEN TEST",
                    "email": "technicien.test@electricite.sn",
                    "entity": "SENELEC",
                    "group": "TECHNICIEN"
                },
                {
                    "code": "5893",
                    "signature": "AGENT MAINTENANCE",
                    "email": "agent.maintenance@electricite.sn",
                    "entity": "SENELEC",
                    "group": "USER"
                }
            ]

            log(f"Injection de {len(users_to_provision)} utilisateurs de reference...")
            for u in users_to_provision:
                check_sql = text("SELECT 1 FROM dbo.coswin_user WHERE cwcu_code = :code")
                row = conn.execute(check_sql, {"code": u["code"]}).fetchone()
                
                if not row:
                    insert_sql = text("""
                        INSERT INTO dbo.coswin_user (cwcu_code, cwcu_signature, cwcu_email, cwcu_entity, cwcu_preferred_group, cwcu_is_absent)
                        VALUES (:code, :sig, :email, :entity, :group, 0)
                    """)
                    conn.execute(insert_sql, {
                        "code": u["code"],
                        "sig": u["signature"],
                        "email": u["email"],
                        "entity": u["entity"],
                        "group": u["group"]
                    })
                    log(f"   + Ajoute: [{u['code']}] {u['signature']} ({u['email']}) - Groupe: {u['group']}")
                else:
                    log(f"   -> Deja present: [{u['code']}] {u['signature']}")

            # 3. Récapitulatif des utilisateurs présents dans la table
            log("\nListe finale des utilisateurs dans dbo.coswin_user:")
            rows = conn.execute(text("SELECT pk_coswin_user, cwcu_code, cwcu_signature, cwcu_email, cwcu_entity, cwcu_preferred_group FROM dbo.coswin_user")).fetchall()
            for r in rows:
                log(f"   * ID: {r[0]} | Code: {r[1]} | Nom: {r[2]} | Email: {r[3]} | Entite: {r[4]} | Groupe: {r[5]}")

            log(f"\nTOTAL: {len(rows)} utilisateur(s) present(s) dans dbo.coswin_user.")
            log("SUCCES: Le provisionnement de la table coswin_user s'est termine sans erreur !")

    except Exception as e:
        log(f"ERREUR LORS DU PROVISIONNEMENT: {e}")

if __name__ == "__main__":
    main()

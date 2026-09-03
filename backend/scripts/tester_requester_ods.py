import os
import sys
import datetime
from pathlib import Path
import urllib.parse

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

SCRIPT_DIR = Path(__file__).resolve().parent
BACKEND_DIR = SCRIPT_DIR.parent
sys.path.insert(0, str(BACKEND_DIR))

from sqlalchemy import create_engine, text

LOG_FILE = BACKEND_DIR.parent / "rapport_utilisateurs_requester.txt"

def log(msg: str):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    formatted = f"[{timestamp}] {msg}"
    print(formatted)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(formatted + "\n")

def main():
    with open(LOG_FILE, "w", encoding="utf-8") as f:
        f.write("====================================================\n")
        f.write("  TEST LECTURE TABLE COSWIN_USER DANS GMAO_MUTUALISE_ODS\n")
        f.write("====================================================\n\n")

    log("DEBUT du test de lecture depuis gmao_mutualise_ODS.dbo.COSWIN_USER sur srv-bddomtech...")

    host = "srv-bddomtech"
    port = "1433"
    user = "cmdt"
    password = "cmdt2023"
    dbname = "gmao_mutualise_ODS"

    log(f"Connexion a Host={host}:{port}, DB={dbname}, User={user}...")

    try:
        dsn = f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={host},{port};DATABASE={dbname};UID={user};PWD={password};TrustServerCertificate=yes;Encrypt=no"
        url = "mssql+pyodbc:///?odbc_connect=" + urllib.parse.quote_plus(dsn)
        engine = create_engine(url, connect_args={"timeout": 5}, echo=False)

        with engine.connect() as conn:
            log(f"SUCCESS: Connexion etablie avec succes sur {host}:{port} ({dbname}) !")

            sql_count = text("SELECT COUNT(*) FROM dbo.COSWIN_USER")
            total_count = conn.execute(sql_count).scalar()
            log(f"🔥 TOTAL UTILISATEURS TROUVÉS DANS COSWIN_USER: {total_count}")

            sql = text("""
                SELECT DISTINCT TOP 50 PK_COSWIN_USER as pk, CWCU_CODE as code, CWCU_SIGNATURE as username, 
                       CWCU_EMAIL as email, CWCU_ENTITY as entity, CWCU_PREFERRED_GROUP as preferred_group
                FROM dbo.COSWIN_USER
                ORDER BY CWCU_SIGNATURE ASC
            """)
            rows = conn.execute(sql).fetchall()

            log(f"\n📋 Extrait des 50 premiers utilisateurs sur {total_count} :")
            log("-------------------------------------------------------------------------")
            for r in rows:
                code_val = str(r[1]).strip() if r[1] is not None else ""
                name_val = str(r[2]).strip() if r[2] is not None else ""
                email_val = str(r[3]).strip() if r[3] is not None else ""
                entity_val = str(r[4]).strip() if r[4] is not None else ""
                group_val = str(r[5]).strip() if r[5] is not None else ""
                log(f" • Code: {code_val:<15} | Nom: {name_val:<30} | Email: {email_val:<30} | Entité: {entity_val:<10} | Groupe: {group_val}")
            log("-------------------------------------------------------------------------")
            log("\nSUCCÈS PARFAIT: La lecture de la vraie table COSWIN_USER s'est terminée sans aucune erreur !")

    except Exception as e:
        log(f"\n❌ ERREUR LORS DE L'INTERROGATION DE COSWIN_USER: {e}")

if __name__ == "__main__":
    main()

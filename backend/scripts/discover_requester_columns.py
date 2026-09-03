import sys
import datetime
from pathlib import Path
import urllib.parse
from sqlalchemy import create_engine, text

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

SCRIPT_DIR = Path(__file__).resolve().parent
BACKEND_DIR = SCRIPT_DIR.parent
LOG_FILE = BACKEND_DIR.parent / "rapport_colonnes_requester.txt"

def log(msg: str):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    formatted = f"[{timestamp}] {msg}"
    print(formatted)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(formatted + "\n")

def main():
    with open(LOG_FILE, "w", encoding="utf-8") as f:
        f.write("====================================================\n")
        f.write("  INSPECTION COLONNES REQUESTER DANS GMAO_ODS\n")
        f.write("====================================================\n\n")

    host = "srv-bddomtech"
    port = "1433"
    user = "cmdt"
    password = "cmdt2023"
    dbname = "gmao_ODS"

    log(f"Connexion a {dbname} sur {host}:{port}...")

    try:
        dsn = f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={host},{port};DATABASE={dbname};UID={user};PWD={password};TrustServerCertificate=yes;Encrypt=no"
        url = "mssql+pyodbc:///?odbc_connect=" + urllib.parse.quote_plus(dsn)
        engine = create_engine(url, connect_args={"timeout": 5}, echo=False)

        with engine.connect() as conn:
            log(f"SUCCESS: Connecte a {dbname} !")

            # 1. Obtenir TOUTES les colonnes de la table REQUESTER
            sql_cols = text("""
                SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_NAME = 'REQUESTER'
                ORDER BY ORDINAL_POSITION
            """)
            columns = conn.execute(sql_cols).fetchall()

            log(f"\n📋 COLONNES EXACTES DE LA TABLE REQUESTER ({len(columns)} colonnes) :")
            log("-------------------------------------------------------------------------")
            for col_name, data_type, max_len in columns:
                len_str = f"({max_len})" if max_len else ""
                log(f" • Colonne: {col_name:<30} | Type: {data_type}{len_str}")
            log("-------------------------------------------------------------------------")

            # 2. Obtenir un échantillon des 3 premières lignes avec SELECT *
            log("\n📷 Échantillon des 3 premières lignes (SELECT TOP 3 * FROM REQUESTER) :")
            sample_rows = conn.execute(text("SELECT TOP 3 * FROM REQUESTER")).fetchall()
            col_names = [c[0] for c in columns]
            for idx, r in enumerate(sample_rows, 1):
                log(f"\n   --- Ligne #{idx} ---")
                for cname, val in zip(col_names, r):
                    if val is not None:
                        log(f"      {cname}: {val}")

            log("\nSUCCÈS: Inspection des colonnes de REQUESTER terminée !")

    except Exception as e:
        log(f"\n❌ ERREUR: {e}")

if __name__ == "__main__":
    main()

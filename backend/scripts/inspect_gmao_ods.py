import sys
import datetime
from pathlib import Path
import urllib.parse
from sqlalchemy import create_engine, text

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

LOG_FILE = Path(__file__).resolve().parent.parent.parent / "rapport_gmao_ods.txt"

def log(msg: str):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    formatted = f"[{timestamp}] {msg}"
    print(formatted)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(formatted + "\n")

def main():
    with open(LOG_FILE, "w", encoding="utf-8") as f:
        f.write("====================================================\n")
        f.write("  INSPECTION DE LA BASE GMAO_ODS SUR SRV-BDDOMTECH\n")
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
        engine = create_engine(url, connect_args={"timeout": 10}, echo=False)

        with engine.connect() as conn:
            log(f"SUCCESS: Connecte a {dbname} !")

            # 1. Lister TOUTES les tables de gmao_ODS
            tables = conn.execute(text("SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' ORDER BY TABLE_NAME")).fetchall()
            log(f"\nListe complete des {len(tables)} tables dans gmao_ODS:")
            for schema, tname in tables:
                log(f"   • {schema}.{tname}")

            # 2. Rechercher les tables contenant le mot USER ou REQUESTER ou EMPLOYEE ou AGENT
            user_tables = [f"{s}.{t}" for s, t in tables if any(k in t.lower() for k in ["user", "request", "employe", "agent", "person"])]
            log(f"\nTables suspectes d'identite/utilisateurs ({len(user_tables)}):")
            for ut in user_tables:
                try:
                    count = conn.execute(text(f"SELECT COUNT(*) FROM {ut}")).scalar()
                    log(f"   --> {ut} : {count} ligne(s)")
                    
                    # Inspecter la structure et les premières lignes s'il y a des données
                    cols = conn.execute(text(f"SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='{ut.split('.')[-1]}'")).fetchall()
                    col_names = [c[0] for c in cols]
                    log(f"       Colonnes: {', '.join(col_names[:10])}")
                    
                    if count > 0:
                        sample = conn.execute(text(f"SELECT TOP 3 * FROM {ut}")).fetchall()
                        log(f"       Exemples de lignes: {sample}")
                except Exception as e_ut:
                    log(f"       Note sur {ut}: {e_ut}")

    except Exception as e:
        log(f"ERREUR: {e}")

if __name__ == "__main__":
    main()

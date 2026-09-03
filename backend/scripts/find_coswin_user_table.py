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
LOG_FILE = BACKEND_DIR.parent / "rapport_recherche_coswin_user.txt"

def log(msg: str):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    formatted = f"[{timestamp}] {msg}"
    print(formatted)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(formatted + "\n")

def search_in_server(host: str, port: str, user: str, password: str):
    log(f"\n====================================================")
    log(f"🔍 RECHERCHE DE 'coswin_user' SUR: Host={host}:{port}, User={user}")
    log(f"====================================================")

    try:
        dsn = f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={host},{port};DATABASE=master;UID={user};PWD={password};TrustServerCertificate=yes;Encrypt=no"
        url = "mssql+pyodbc:///?odbc_connect=" + urllib.parse.quote_plus(dsn)
        engine = create_engine(url, connect_args={"timeout": 5}, echo=False)

        with engine.connect() as conn:
            log(f"SUCCESS: Connecte au serveur SQL {host}:{port} !")

            # 1. Lister toutes les bases de données du serveur
            dbs = conn.execute(text("SELECT name FROM sys.databases WHERE state_desc = 'ONLINE' ORDER BY name")).fetchall()
            db_names = [d[0] for d in dbs if d[0] not in ['master', 'tempdb', 'model', 'msdb']]
            log(f"Bases de donnees a inspecter ({len(db_names)}) : {', '.join(db_names)}")

            found_any = False
            for dbname in db_names:
                try:
                    # Tenter d'inspecter les tables dans cette base
                    sql_tables = text(f"""
                        SELECT TABLE_SCHEMA, TABLE_NAME 
                        FROM [{dbname}].INFORMATION_SCHEMA.TABLES 
                        WHERE TABLE_TYPE='BASE TABLE' AND (
                            LOWER(TABLE_NAME) LIKE '%coswin%user%' OR 
                            LOWER(TABLE_NAME) LIKE '%coswin%' OR 
                            LOWER(TABLE_NAME) = 'coswin_user' OR
                            LOWER(TABLE_NAME) LIKE '%user%'
                        )
                        ORDER BY TABLE_NAME
                    """)
                    matching_tables = conn.execute(sql_tables).fetchall()

                    if matching_tables:
                        log(f"\n📌 BASE [{dbname}] -> {len(matching_tables)} table(s) trouvee(s) :")
                        for schema, tname in matching_tables:
                            try:
                                count = conn.execute(text(f"SELECT COUNT(*) FROM [{dbname}].[{schema}].[{tname}]")).scalar()
                                log(f"   • Table: [{dbname}].[{schema}].[{tname}] -> {count} ligne(s)")
                                
                                if "coswin" in tname.lower():
                                    found_any = True
                                    log(f"   🎯 TARGET TROUVÉE : La table '{tname}' se trouve dans la base [{dbname}] !")
                                    
                                    # Lister ses colonnes
                                    cols = conn.execute(text(f"""
                                        SELECT COLUMN_NAME, DATA_TYPE 
                                        FROM [{dbname}].INFORMATION_SCHEMA.COLUMNS 
                                        WHERE TABLE_NAME = '{tname}'
                                    """)).fetchall()
                                    col_str = ", ".join([f"{c[0]} ({c[1]})" for c in cols])
                                    log(f"       Colonnes: {col_str}")

                            except Exception as e_cnt:
                                log(f"   • Table: [{dbname}].[{schema}].[{tname}] -> (lecture impossible: {e_cnt})")

                except Exception as e_db:
                    # Ignorer les bases non accessibles ou restreintes
                    pass

            if not found_any:
                log(f"\nRESULTAT: La table 'coswin_user' n'a pas ete trouvee sous ce nom exact sur {host}.")

    except Exception as e:
        log(f"❌ Impossible de se connecter a {host}:{port} -> {e}")

def main():
    with open(LOG_FILE, "w", encoding="utf-8") as f:
        f.write("====================================================\n")
        f.write("  RECHERCHE DE LA TABLE COSWIN_USER SUR TOUTES LES BASES\n")
        f.write("====================================================\n\n")

    log("DEBUT de la recherche globale de 'coswin_user'...")

    # 1. Tester sur le serveur distant Senelec
    search_in_server("srv-bddomtech", "1433", "cmdt", "cmdt2023")

    # 2. Tester sur le serveur local
    search_in_server("127.0.0.1", "1433", "sa", "Mssql_2025@")

if __name__ == "__main__":
    main()

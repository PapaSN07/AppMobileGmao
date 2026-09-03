import os
import sys
import datetime
from pathlib import Path
import urllib.parse

# Encodage console Windows
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

from sqlalchemy import create_engine, text

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent.parent
LOG_FILE = PROJECT_DIR / "rapport_test_connexion.txt"

def log(msg: str):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    formatted = f"[{timestamp}] {msg}"
    print(formatted)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(formatted + "\n")

def test_connection_target(host: str, port: str, user: str, password: str, dbname: str = "master"):
    log(f"\n--- TEST CONNEXION VERS: Host={host}:{port}, DB={dbname}, User={user} ---")
    try:
        dsn = f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={host},{port};DATABASE={dbname};UID={user};PWD={password};TrustServerCertificate=yes;Encrypt=no"
        url = "mssql+pyodbc:///?odbc_connect=" + urllib.parse.quote_plus(dsn)
        engine = create_engine(url, connect_args={"timeout": 5}, echo=False)

        with engine.connect() as conn:
            log(f"SUCCESS: Connexion etablie avec succes sur {host}:{port} !")
            
            # 1. Lister les bases de données accessibles
            databases = conn.execute(text("SELECT name FROM sys.databases")).fetchall()
            db_names = [d[0] for d in databases]
            log(f"Bases de donnees disponibles ({len(db_names)}): {', '.join(db_names)}")

            # 2. Vérifier si Gmao_ODS ou gmao_mobile ou gmao_backend existe
            for target_db in ["Gmao_ODS", "gmao_mobile", "gmao_backend", "Coswin_DDOT"]:
                if target_db.lower() in [d.lower() for d in db_names]:
                    log(f"\n   Found database match: '{target_db}'")
                    try:
                        conn.execute(text(f"USE [{target_db}]"))
                        tables = conn.execute(text("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'")).fetchall()
                        t_names = [t[0] for t in tables]
                        log(f"   Tables dans '{target_db}' ({len(t_names)}): {', '.join(t_names[:15])}...")
                        
                        # Vérifier coswin_user
                        if "coswin_user" in [t.lower() for t in t_names]:
                            count = conn.execute(text(f"SELECT COUNT(*) FROM [{target_db}].dbo.coswin_user")).scalar()
                            log(f"   !!! TABLE coswin_user TROUVEE dans '{target_db}' avec {count} utilisateur(s) !!!")
                    except Exception as e_db:
                        log(f"   Note lors de la lecture de '{target_db}': {e_db}")

            return True

    except Exception as e:
        log(f"ECHEC Connexion vers {host}:{port} -> Erreur: {e}")
        return False

def main():
    with open(LOG_FILE, "w", encoding="utf-8") as f:
        f.write("====================================================\n")
        f.write("  RAPPORT DE TEST DE CONNEXION SERVEUR DISTANT\n")
        f.write("====================================================\n\n")

    log("DEBUT du test de connexion reseau distant...")

    # Cibles à tester (combinaisons hôtes / identifiants retrouvés dans l'historique)
    targets = [
        {"host": "srv-bddomtech", "port": "1433", "user": "cmdt", "pass": "cmdt2023"},
        {"host": "srvdomtech", "port": "1433", "user": "cmdt", "pass": "cmdt2023"},
        {"host": "srv-bddomtech", "port": "1433", "user": "sa", "pass": "Mssql_2025@"},
        {"host": "10.101.3.171", "port": "1433", "user": "cmdt", "pass": "cmdt2023"},
    ]

    any_success = False
    for t in targets:
        success = test_connection_target(t["host"], t["port"], t["user"], t["pass"])
        if success:
            any_success = True

    if any_success:
        log("\nSYNTHESE: Au moins un serveur distant a repondu avec succes !")
    else:
        log("\nSYNTHESE: Aucun serveur distant n'a repondu. Verifiez que le cable Senelec est bien branche.")

if __name__ == "__main__":
    main()

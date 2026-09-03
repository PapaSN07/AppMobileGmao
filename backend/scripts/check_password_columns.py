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
LOG_FILE = BACKEND_DIR.parent / "rapport_inspection_passwords.txt"

def log(msg: str):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    formatted = f"[{timestamp}] {msg}"
    print(formatted)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(formatted + "\n")

def main():
    with open(LOG_FILE, "w", encoding="utf-8") as f:
        f.write("====================================================\n")
        f.write("  INSPECTION COLONNES MOT DE PASSE EN BASE SENELEC\n")
        f.write("====================================================\n\n")

    host = "srv-bddomtech"
    port = "1433"
    user = "cmdt"
    password = "cmdt2023"
    dbname = "gmao_mutualise_ODS"

    log("DEBUT de l'inspection des colonnes mot de passe dans gmao_mutualise_ODS.dbo.COSWIN_USER...")

    try:
        dsn = f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={host},{port};DATABASE={dbname};UID={user};PWD={password};TrustServerCertificate=yes;Encrypt=no"
        url = "mssql+pyodbc:///?odbc_connect=" + urllib.parse.quote_plus(dsn)
        engine = create_engine(url, connect_args={"timeout": 5}, echo=False)

        with engine.connect() as conn:
            log("SUCCESS: Connecte a gmao_mutualise_ODS !")

            # 1. Obtenir toutes les colonnes contenant 'PWD' ou 'PASS'
            sql_cols = text("""
                SELECT COLUMN_NAME, DATA_TYPE 
                FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_NAME = 'COSWIN_USER' 
                  AND (LOWER(COLUMN_NAME) LIKE '%pass%' OR LOWER(COLUMN_NAME) LIKE '%pwd%')
                ORDER BY COLUMN_NAME
            """)
            cols = conn.execute(sql_cols).fetchall()
            log(f"\n📋 Colonnes de mot de passe trouvees dans COSWIN_USER ({len(cols)}) :")
            for cname, dtype in cols:
                log(f"   • {cname:<30} ({dtype})")

            # 2. Inspecter l'utilisateur ADMIN_SML s'il existe
            log("\n🔍 Inspection des valeurs pour l'utilisateur 'ADMIN_SML' :")
            sql_user = text("""
                SELECT CWCU_CODE, CWCU_SIGNATURE, CWCU_EMAIL, CWCU_MOBILE_PASSWORD, CWCU_EASY_PASSWORD
                FROM dbo.COSWIN_USER
                WHERE LOWER(CWCU_CODE) = 'admin_sml' OR LOWER(CWCU_SIGNATURE) = 'admin_sml' OR LOWER(CWCU_EMAIL) = 'admin_sml'
            """)
            user_rows = conn.execute(sql_user).fetchall()
            if user_rows:
                for r in user_rows:
                    log(f"   • Code: {r[0]} | Nom: {r[1]} | Email: {r[2]}")
                    log(f"     CWCU_MOBILE_PASSWORD: {'*** (Renseigné)' if r[3] else '(Vide/Null)'}")
                    log(f"     CWCU_EASY_PASSWORD:   {'*** (Renseigné)' if r[4] else '(Vide/Null)'}")
            else:
                log("   (Utilisateur ADMIN_SML non trouve directement dans ce filtre)")

    except Exception as e:
        log(f"❌ ERREUR: {e}")

if __name__ == "__main__":
    main()

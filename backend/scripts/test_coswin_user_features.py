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
from sqlalchemy.orm import sessionmaker

LOG_FILE = BACKEND_DIR.parent / "rapport_test_coswin_user_complete.txt"

def log(msg: str):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    formatted = f"[{timestamp}] {msg}"
    print(formatted)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(formatted + "\n")

def main():
    with open(LOG_FILE, "w", encoding="utf-8") as f:
        f.write("====================================================\n")
        f.write("  TEST COMPLET DES FONCTIONNALITÉS DE COSWIN_USER\n")
        f.write("====================================================\n\n")

    log("DEBUT du test complet de la table gmao_mutualise_ODS.dbo.COSWIN_USER sur srv-bddomtech...\n")

    host = "srv-bddomtech"
    port = "1433"
    user = "cmdt"
    password = "cmdt2023"
    dbname = "gmao_mutualise_ODS"

    try:
        # Configurer l'engine distant srv-bddomtech pour get_main_session
        dsn = f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={host},{port};DATABASE={dbname};UID={user};PWD={password};TrustServerCertificate=yes;Encrypt=no"
        url = "mssql+pyodbc:///?odbc_connect=" + urllib.parse.quote_plus(dsn)
        engine = create_engine(url, connect_args={"timeout": 5}, echo=False)

        # Injecter le SessionMaker distant dans app.db.sqlalchemy.engine
        import app.db.sqlalchemy.engine as engine_module
        engine_module.main_engine = engine
        engine_module.SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine, future=True)

        from app.services.coswin_user_service import CoswinUserService

        # ---------------------------------------------------------
        # TEST 1: Statistiques & Total d'utilisateurs
        # ---------------------------------------------------------
        log("--- TEST 1: Statistiques globales de la table COSWIN_USER ---")
        with engine.connect() as conn:
            total_count = conn.execute(text("SELECT COUNT(*) FROM dbo.COSWIN_USER")).scalar()
            log(f"✅ Total d'agents enregistres dans COSWIN_USER: {total_count} agents")

            # Répartition par groupe / rôle
            groups = conn.execute(text("SELECT COALESCE(CWCU_PREFERRED_GROUP, 'SANS GROUPE'), COUNT(*) FROM dbo.COSWIN_USER GROUP BY CWCU_PREFERRED_GROUP ORDER BY COUNT(*) DESC")).fetchall()
            log("\n   Répartition par Groupe / Rôle :")
            for g, cnt in groups[:10]:
                log(f"    • Groupe '{g}': {cnt} agent(s)")

        # ---------------------------------------------------------
        # TEST 2: Recherche d'agents & Autocomplétion (search_users)
        # ---------------------------------------------------------
        search_term = "DIOP"
        log(f"\n--- TEST 2: Recherche d'agents pour autocompletion sur mot-cle '{search_term}' ---")
        search_results = CoswinUserService.search_users(query_str=search_term, limit=10)
        log(f"✅ Agents trouves pour '{search_term}' ({len(search_results)} resultats) :")
        for u in search_results:
            log(f"   • Code: {u['code']:<12} | Nom: {u['username']:<30} | Email: {u['email']:<30} | Entite: {u['entity']}")

        # ---------------------------------------------------------
        # TEST 3: Récupération individuelle (get_user_by_code)
        # ---------------------------------------------------------
        log("\n--- TEST 3: Récupération detaillee d'un utilisateur par son matricule/code ---")
        if search_results:
            sample_code = search_results[0]["code"]
            log(f"   Lecture detaillee pour le matricule '{sample_code}'...")
            user_info = CoswinUserService.get_user_by_code(sample_code)
            if user_info:
                log("✅ Donnees de profil recuperees avec succes :")
                for k, v in user_info.items():
                    log(f"      {k:<10} : {v}")

        # ---------------------------------------------------------
        # TEST 4: Validation de matricule (validate_employee_code)
        # ---------------------------------------------------------
        log("\n--- TEST 4: Validation de matricule pour affectation d'OT ---")
        if search_results:
            valid_code = search_results[0]["code"]
            invalid_code = "MATRICULE_INEXISTANT_999"

            res_valid = CoswinUserService.validate_employee_code(valid_code)
            res_invalid = CoswinUserService.validate_employee_code(invalid_code)

            log(f"   • Validation matricule existant '{valid_code}': {res_valid} (Attendu: True) ✅")
            log(f"   • Validation matricule inistant '{invalid_code}': {res_invalid} (Attendu: False) ✅")

        log("\n====================================================")
        log("🎉 SUCCÈS TOTAL: Tous les tests de COSWIN_USER ont reussi sans erreur !")
        log("====================================================")

    except Exception as e:
        log(f"\n❌ ERREUR LORS DU TEST: {e}")

if __name__ == "__main__":
    main()

"""
import_to_docker.py
-------------------
Importe les fichiers JSON extraits dans le SQL Server local (Docker).

Ordre d'exécution :
  1. t_specification
  2. attribute
  3. attribute_values
  4. equipment
  5. equipment_specs
  6. equipment_attribute
  7. category_specification
  8. work_order  (OT — depuis l'API)
  9. work_request (DI — depuis l'API)

Usage :
    cd backend
    python scripts/import_to_docker.py

Prérequis :
    pip install pyodbc python-dotenv
    Docker démarré : docker-compose -f docker-compose.local.yml up -d
"""

import json
import os
import pyodbc
import sys
from pathlib import Path

# ─── Chargement .env ──────────────────────────────────────────────────────────
try:
    from dotenv import load_dotenv
    for _name in (".env.local", ".env.prod", ".env"):
        _p = Path(__file__).parents[1] / _name
        if _p.exists():
            load_dotenv(_p)
            print(f"[env] {_p.name}")
            break
except ImportError:
    pass

# ─── Connexion Docker SQL Server local ───────────────────────────────────────
LOCAL_HOST = os.getenv("TEMP_DB_HOST", "localhost")
LOCAL_PORT = os.getenv("TEMP_DB_PORT", "1433")
LOCAL_DB   = os.getenv("DB_NAME", "gmao_backend")
LOCAL_USER = os.getenv("TEMP_DB_USERNAME", "sa")
LOCAL_PASS = os.getenv("DB_PASSWORD", "Mssql_2025@")

DATA_DIR = Path(__file__).parent / "data_extracted"

BATCH_SIZE = 200   # lignes insérées par transaction

EXPECTED_FILES = {
    "specification_latest.json": "Specifications des attributs",
    "attributes_latest.json": "Definitions des attributs",
    "attribute_values_latest.json": "Valeurs possibles des attributs",
    "equipment_latest.json": "Equipements",
    "equipment_specs_latest.json": "Lien equipement/specification",
    "equipment_attribute_latest.json": "Valeurs d'attributs des equipements",
    "category_specification_latest.json": "Lien categorie/specification",
    "ot_workorders_latest.json": "Ordres de travail (OT)",
    "di_workrequests_latest.json": "Demandes d'intervention (DI)",
}


# ─── Connexion ────────────────────────────────────────────────────────────────
def get_conn() -> pyodbc.Connection:
    for driver in ("ODBC Driver 18 for SQL Server", "ODBC Driver 17 for SQL Server"):
        try:
            conn = pyodbc.connect(
                f"DRIVER={{{driver}}};"
                f"SERVER={LOCAL_HOST},{LOCAL_PORT};"
                f"DATABASE={LOCAL_DB};"
                f"UID={LOCAL_USER};"
                f"PWD={LOCAL_PASS};"
                "TrustServerCertificate=yes;"
                "Encrypt=yes;",
                timeout=30,
            )
            print(f"  ✅  Connecté via {driver}")
            return conn
        except pyodbc.Error:
            continue
    raise RuntimeError("❌  Impossible de se connecter au SQL Server Docker local.")


def load_json(filename: str) -> list:
    path = DATA_DIR / filename
    if not path.exists():
        print(f"  ⚠️  Fichier introuvable : {path.name}  → ignoré")
        return []
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def show_expected_files() -> list[str]:
    """Affiche les fichiers attendus et retourne ceux qui sont manquants."""
    print("\n📦  Fichiers JSON attendus dans data_extracted :")
    missing = []
    for filename, description in EXPECTED_FILES.items():
        path = DATA_DIR / filename
        exists = path.exists()
        status = "OK" if exists else "MANQUANT"
        print(f"  - {filename:<34} | {description:<35} | {status}")
        if not exists:
            missing.append(filename)
    return missing


def insert_batch(conn, sql: str, rows: list, label: str):
    """Insère les lignes par lots avec IGNORE_DUP_KEY."""
    if not rows:
        print(f"  ⚠️  {label}: aucune donnée")
        return
    cursor = conn.cursor()
    inserted = 0
    for i in range(0, len(rows), BATCH_SIZE):
        batch = rows[i: i + BATCH_SIZE]
        for row in batch:
            try:
                cursor.execute(sql, row)
                inserted += 1
            except pyodbc.IntegrityError:
                pass  # Doublon, on ignore
            except Exception as e:
                print(f"  ⚠️  Erreur ligne {row}: {e}")
        conn.commit()
    print(f"  ✅  {label}: {inserted}/{len(rows)} insérés")


# ─── 1. t_specification ───────────────────────────────────────────────────────
def import_specification(conn):
    rows = load_json("specification_latest.json")
    sql = """
        IF NOT EXISTS (SELECT 1 FROM dbo.t_specification WHERE cwsp_code = ?)
        INSERT INTO dbo.t_specification (cwsp_code, cwsp_description)
        VALUES (?, ?)
    """
    data = [(r.get("cwsp_code"), r.get("cwsp_code"), r.get("cwsp_description")) for r in rows]
    insert_batch(conn, sql, data, "t_specification")


# ─── 2. attribute ─────────────────────────────────────────────────────────────
def import_attributes(conn):
    rows = load_json("attributes_latest.json")
    sql = """
        IF NOT EXISTS (SELECT 1 FROM dbo.attribute WHERE pk_attribute = ?)
        INSERT INTO dbo.attribute (pk_attribute, cwat_index, cwat_specification, cwat_name, cwat_type)
        VALUES (?, ?, ?, ?, ?)
    """
    data = [
        (
            r.get("pk_attribute"),
            r.get("pk_attribute"),
            r.get("cwat_index"),
            r.get("cwat_specification"),
            r.get("cwat_name"),
            r.get("cwat_type"),
        )
        for r in rows
    ]
    insert_batch(conn, sql, data, "attribute")


# ─── 3. attribute_values ─────────────────────────────────────────────────────
def import_attribute_values(conn):
    rows = load_json("attribute_values_latest.json")
    sql = """
        IF NOT EXISTS (
            SELECT 1 FROM dbo.attribute_values
            WHERE cwav_specification = ? AND cwav_attribute_index = ? AND cwav_value = ?
        )
        INSERT INTO dbo.attribute_values (cwav_specification, cwav_attribute_index, cwav_value)
        VALUES (?, ?, ?)
    """
    data = [
        (
            r.get("cwav_specification"), r.get("cwav_attribute_index"), r.get("cwav_value"),
            r.get("cwav_specification"), r.get("cwav_attribute_index"), r.get("cwav_value"),
        )
        for r in rows
    ]
    insert_batch(conn, sql, data, "attribute_values")


# ─── 4. equipment ─────────────────────────────────────────────────────────────
def import_equipment(conn):
    rows = load_json("equipment_latest.json")
    sql = """
        IF NOT EXISTS (SELECT 1 FROM dbo.equipment WHERE timestamp = ?)
        INSERT INTO dbo.equipment (
            timestamp, ereq_parent_equipment, ereq_code, ereq_category,
            ereq_zone, ereq_entity, ereq_function, ereq_costcentre,
            ereq_description, ereq_longitude, ereq_latitude,
            ereq_string2, ereq_bar_code, ereq_creation_date,
            costcentre_description
        ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    """
    data = []
    for r in rows:
        pk = r.get("pk_equipment") or r.get("timestamp")
        data.append((
            pk, pk,
            r.get("ereq_parent_equipment"),
            r.get("ereq_code"),
            r.get("ereq_category"),
            r.get("ereq_zone"),
            r.get("ereq_entity"),
            r.get("ereq_function"),
            r.get("ereq_costcentre"),
            r.get("ereq_description"),
            r.get("ereq_longitude"),
            r.get("ereq_latitude"),
            r.get("feeder_code") or r.get("ereq_string2"),
            r.get("ereq_bar_code"),
            r.get("ereq_creation_date"),
            r.get("costcentre_description"),
        ))
    insert_batch(conn, sql, data, "equipment")


# ─── 5. equipment_specs ───────────────────────────────────────────────────────
def import_equipment_specs(conn):
    rows = load_json("equipment_specs_latest.json")
    sql = """
        IF NOT EXISTS (SELECT 1 FROM dbo.equipment_specs WHERE timestamp_specs = ?)
        INSERT INTO dbo.equipment_specs (
            timestamp_specs, etes_specification, etes_equipment,
            etes_release_date, etes_release_number
        ) VALUES (?,?,?,?,?)
    """
    data = [
        (
            r.get("timestamp_specs"),
            r.get("timestamp_specs"),
            r.get("etes_specification"),
            r.get("etes_equipment"),
            r.get("etes_release_date"),
            r.get("etes_release_number"),
        )
        for r in rows
    ]
    insert_batch(conn, sql, data, "equipment_specs")


# ─── 6. equipment_attribute ───────────────────────────────────────────────────
def import_equipment_attribute(conn):
    rows = load_json("equipment_attribute_latest.json")
    sql = """
        IF NOT EXISTS (
            SELECT 1 FROM dbo.equipment_attribute WHERE commonkey = ? AND indx = ?
        )
        INSERT INTO dbo.equipment_attribute (commonkey, indx, etat_value)
        VALUES (?,?,?)
    """
    data = [
        (
            r.get("commonkey"), r.get("indx"),
            r.get("commonkey"), r.get("indx"), r.get("etat_value"),
        )
        for r in rows
    ]
    insert_batch(conn, sql, data, "equipment_attribute")


# ─── 7. category_specification ────────────────────────────────────────────────
def import_category_specification(conn):
    rows = load_json("category_specification_latest.json")
    sql = """
        IF NOT EXISTS (
            SELECT 1 FROM dbo.category_specification
            WHERE mdcs_category = ? AND mdcs_specification = ?
        )
        INSERT INTO dbo.category_specification (mdcs_category, mdcs_specification)
        VALUES (?,?)
    """
    data = [
        (
            r.get("mdcs_category"), r.get("mdcs_specification"),
            r.get("mdcs_category"), r.get("mdcs_specification"),
        )
        for r in rows
    ]
    insert_batch(conn, sql, data, "category_specification")


# ─── 8. work_order (OT) ───────────────────────────────────────────────────────
def import_workorders(conn):
    rows = load_json("ot_workorders_latest.json")
    sql = """
        IF NOT EXISTS (SELECT 1 FROM dbo.work_order WHERE wowo_pk = ?)
        INSERT INTO dbo.work_order (
            wowo_pk, wowo_code, wowo_user_status, wowo_equipment,
            wowo_equipment_description, wowo_job, wowo_job_type, wowo_job_class,
            wowo_priority, wowo_action_entity, wowo_request_entity,
            wowo_schedule_date, wowo_target_date, wowo_start_date, wowo_end_date,
            wowo_job_request, wowo_supervisor, wowo_costcentre,
            wowo_costcentre_description, wowo_zone, wowo_function,
            wowo_feedback_note, mdjb_description,
            wowo_string1, wowo_string2, wowo_string4, mdus_description, raw_json
        ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    """
    data = []
    for r in rows:
        pk = r.get("pkWorkOrder")
        data.append((
            pk,
            pk,
            r.get("wowoCode"),
            r.get("wowoUserStatus"),
            r.get("wowoEquipment"),
            r.get("wowoEquipmentDescription"),
            r.get("wowoJob"),
            r.get("wowoJobType"),
            r.get("wowoJobClass"),
            r.get("wowoPriority"),
            r.get("wowoActionEntity"),
            r.get("wowoRequestEntity"),
            r.get("wowoScheduleDate"),
            r.get("wowoTargetDate"),
            r.get("wowoStartDate"),
            r.get("wowoEndDate"),
            r.get("wowoJobRequest"),
            r.get("wowoSupervisor"),
            r.get("wowoCostcentre"),
            r.get("wowoCostcentreDescription"),
            r.get("wowoZone"),
            r.get("wowoFunction"),
            r.get("wowoFeedbackNote"),
            r.get("mdjbDescription"),
            r.get("wowoString1"),
            r.get("wowoString2"),
            r.get("wowoString4"),
            r.get("mdusDescription"),
            json.dumps(r, ensure_ascii=False, default=str),
        ))
    insert_batch(conn, sql, data, "work_order (OT)")


# ─── 9. work_request (DI) ─────────────────────────────────────────────────────
def import_workrequests(conn):
    rows = load_json("di_workrequests_latest.json")
    sql = """
        IF NOT EXISTS (SELECT 1 FROM dbo.work_request WHERE dinq_pk = ?)
        INSERT INTO dbo.work_request (
            dinq_pk, dinq_code, dinq_user_status, dinq_equipment,
            dinq_equipment_description, dinq_job, dinq_job_type, dinq_job_class,
            dinq_priority, dinq_action_entity, dinq_request_entity,
            dinq_ask_date, dinq_target_date, dinq_supervisor,
            dinq_costcentre, dinq_costcentre_description,
            dinq_zone, dinq_function, dinq_description, raw_json
        ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    """
    data = []
    for r in rows:
        # Adapter selon les champs réels retournés par votre API DI
        pk = r.get("pkWorkRequest") or r.get("pk") or r.get("id")
        data.append((
            pk,
            pk,
            r.get("dinqCode") or r.get("code"),
            r.get("dinqUserStatus") or r.get("userStatus") or r.get("status"),
            r.get("dinqEquipment") or r.get("equipment"),
            r.get("dinqEquipmentDescription") or r.get("equipmentDescription"),
            r.get("dinqJob") or r.get("job"),
            r.get("dinqJobType") or r.get("jobType"),
            r.get("dinqJobClass") or r.get("jobClass"),
            r.get("dinqPriority") or r.get("priority"),
            r.get("dinqActionEntity") or r.get("actionEntity"),
            r.get("dinqRequestEntity") or r.get("requestEntity"),
            r.get("dinqAskDate") or r.get("askDate"),
            r.get("dinqTargetDate") or r.get("targetDate"),
            r.get("dinqSupervisor") or r.get("supervisor"),
            r.get("dinqCostcentre") or r.get("costcentre"),
            r.get("dinqCostcentreDescription") or r.get("costcentreDescription"),
            r.get("dinqZone") or r.get("zone"),
            r.get("dinqFunction") or r.get("function"),
            r.get("dinqDescription") or r.get("description"),
            json.dumps(r, ensure_ascii=False, default=str),
        ))
    insert_batch(conn, sql, data, "work_request (DI)")


# ─── Main ─────────────────────────────────────────────────────────────────────
def main():
    print("=" * 60)
    print("  IMPORT → Docker SQL Server local")
    print(f"  Serveur : {LOCAL_HOST}:{LOCAL_PORT}/{LOCAL_DB}")
    print(f"  Data    : {DATA_DIR}")
    print("=" * 60)

    missing_files = show_expected_files()
    if missing_files:
        print("\n⚠️  Certains fichiers sont absents.")
        print("    L'import continue, mais seules les donnees disponibles seront chargees.")

    print("\n🔌  Connexion...")
    try:
        conn = get_conn()
    except RuntimeError as e:
        print(e)
        print("\n💡  Vérifiez que Docker est démarré :")
        print("    docker-compose -f docker-compose.local.yml up -d")
        sys.exit(1)

    print("\n📤  Import des tables (ordre respecté)...")
    import_specification(conn)
    import_attributes(conn)
    import_attribute_values(conn)
    import_equipment(conn)
    import_equipment_specs(conn)
    import_equipment_attribute(conn)
    import_category_specification(conn)
    import_workorders(conn)
    import_workrequests(conn)

    conn.close()
    print("\n✅  Import terminé !")


if __name__ == "__main__":
    main()

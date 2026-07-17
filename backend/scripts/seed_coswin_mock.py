import os
import json
import urllib.parse
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

# Load configuration from .env.prod
load_dotenv("c:/Users/X1/AppMobileGmao/backend/.env.prod")

DB_USERNAME = os.getenv("DB_USERNAME")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")

# 1. Engines definition
# Source Database: gmao_backend
dsn_source = f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={DB_HOST},{DB_PORT};DATABASE=gmao_backend;UID={DB_USERNAME};PWD={DB_PASSWORD};TrustServerCertificate=yes;Encrypt=no"
url_source = "mssql+pyodbc:///?odbc_connect=" + urllib.parse.quote_plus(dsn_source)
engine_source = create_engine(url_source)

# Target Database: coswin_mock
dsn_target = f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={DB_HOST},{DB_PORT};DATABASE=coswin_mock;UID={DB_USERNAME};PWD={DB_PASSWORD};TrustServerCertificate=yes;Encrypt=no"
url_target = "mssql+pyodbc:///?odbc_connect=" + urllib.parse.quote_plus(dsn_target)
engine_target = create_engine(url_target)

print("=== STARTING COSWIN MOCK DATABASE SEEDING ===")

# --- Step 1: Copy Reference Data from gmao_backend to coswin_mock ---
ref_tables = [
    {
        "name": "category",
        "columns": ["mdct_code", "mdct_description", "mdct_parent_category", "mdct_system_category", "mdct_level", "mdct_entity"]
    },
    {
        "name": "zone",
        "columns": ["mdzo_code", "mdzo_description", "mdzo_entity"]
    },
    {
        "name": "entity",
        "columns": ["chen_code", "chen_description", "chen_entity_type", "chen_level", "chen_parent_entity", "chen_system_entity"]
    },
    {
        "name": "costcentre",
        "columns": ["mdcc_code", "mdcc_description", "mdcc_entity"]
    },
    {
        "name": "coswin_user",
        "columns": ["cwcu_code", "cwcu_signature", "cwcu_password", "cwcu_email", "cwcu_entity", "cwcu_preferred_group", "cwcu_url_image", "cwcu_is_absent"]
    },
    {
        "name": "equipment",
        "columns": ["ereq_parent_equipment", "ereq_code", "ereq_category", "ereq_zone", "ereq_entity", "ereq_function", "ereq_costcentre", "ereq_description", "ereq_longitude", "ereq_latitude", "ereq_string2", "ereq_bar_code", "ereq_creation_date"]
    }
]

try:
    # Read from Source and Write to Target
    with engine_source.connect() as conn_src:
        with engine_target.begin() as conn_tgt:
            for table_info in ref_tables:
                t_name = table_info["name"]
                cols = table_info["columns"]
                
                print(f"Copying reference table '{t_name}'...")
                
                # Fetch data from source
                cols_str = ", ".join(cols)
                select_query = f"SELECT {cols_str} FROM dbo.{t_name}"
                res_src = conn_src.execute(text(select_query))
                rows = res_src.fetchall()
                
                print(f"  Found {len(rows)} records in source.")
                
                # Clear target table
                conn_tgt.execute(text(f"DELETE FROM dbo.{t_name}"))
                
                # Insert into target
                if rows:
                    placeholders = ", ".join([f":{c}" for c in cols])
                    insert_query = f"INSERT INTO dbo.{t_name} ({cols_str}) VALUES ({placeholders})"
                    
                    for row in rows:
                        row_dict = dict(zip(cols, row))
                        conn_tgt.execute(text(insert_query), row_dict)
                    
                    print(f"  Successfully copied {len(rows)} records to coswin_mock.")
                    
except Exception as e:
    print("❌ Error copying reference data:", e)
    exit(1)


# --- Step 2: Seed Work Orders from JSON file ---
json_path = "c:/Users/X1/AppMobileGmao/API_OT_SUCCESS_EXAMPLE.json"
if not os.path.exists(json_path):
    print(f"❌ Error: Mock JSON file not found at {json_path}")
    exit(1)

with open(json_path, "r", encoding="utf-8") as f:
    workorders = json.load(f)

print(f"\nLoaded {len(workorders)} work orders from JSON.")

try:
    with engine_target.begin() as conn:
        # Clear existing work orders
        print("Clearing existing work orders...")
        conn.execute(text("DELETE FROM dbo.workorder"))
        
        # Helper lists/sets to cache existing unique reference keys and prevent redundant DB checks
        existing_equipments = {r[0] for r in conn.execute(text("SELECT ereq_code FROM dbo.equipment")).fetchall()}
        existing_users = {r[0] for r in conn.execute(text("SELECT cwcu_code FROM dbo.coswin_user")).fetchall()}
        existing_costcentres = {r[0] for r in conn.execute(text("SELECT mdcc_code FROM dbo.costcentre")).fetchall()}
        existing_entities = {r[0] for r in conn.execute(text("SELECT chen_code FROM dbo.entity")).fetchall()}
        existing_zones = {r[0] for r in conn.execute(text("SELECT mdzo_code FROM dbo.zone")).fetchall()}
        existing_categories = {r[0] for r in conn.execute(text("SELECT mdct_code FROM dbo.category")).fetchall()}
        
        # Self-healing insertion logic
        for idx, ot in enumerate(workorders):
            code = ot.get("wowoCode")
            
            # 1. Resolve foreign keys - check if they exist, if not, create dummy records
            eq_code = ot.get("wowoEquipment")
            if eq_code and eq_code not in existing_equipments:
                print(f"  [Self-Healing] Creating missing equipment: {eq_code}")
                # Insert default category, zone, entity, costcentre to satisfy local constraint on equipment table itself!
                # Wait! Let's check what default codes we can use:
                default_category = ot.get("wowoJobClass") or "POSTE"
                default_zone = ot.get("wowoZone") or "DAKAR"
                default_entity = ot.get("wowoRequestEntity") or "DTAE"
                default_costcentre = ot.get("wowoCostcentre") or "DD304"
                
                # Make sure these dependencies exist in their respective tables first!
                if default_category not in existing_categories:
                    conn.execute(text("INSERT INTO dbo.category (mdct_code, mdct_description) VALUES (:code, :desc)"), {"code": default_category, "desc": "Autogenerated Job Class"})
                    existing_categories.add(default_category)
                if default_zone not in existing_zones:
                    conn.execute(text("INSERT INTO dbo.zone (mdzo_code, mdzo_description) VALUES (:code, :desc)"), {"code": default_zone, "desc": "Autogenerated Zone"})
                    existing_zones.add(default_zone)
                if default_entity not in existing_entities:
                    conn.execute(text("INSERT INTO dbo.entity (chen_code, chen_description, chen_entity_type, chen_level) VALUES (:code, :desc, 'AUTOGEN', 1)"), {"code": default_entity, "desc": "Autogenerated Entity"})
                    existing_entities.add(default_entity)
                if default_costcentre not in existing_costcentres:
                    conn.execute(text("INSERT INTO dbo.costcentre (mdcc_code, mdcc_description) VALUES (:code, :desc)"), {"code": default_costcentre, "desc": "Autogenerated Costcentre"})
                    existing_costcentres.add(default_costcentre)
                
                conn.execute(
                    text("""
                        INSERT INTO dbo.equipment (
                            ereq_code, ereq_description, ereq_category, ereq_zone, ereq_entity, ereq_function, ereq_costcentre
                        ) VALUES (
                            :code, :desc, :cat, :zone, :ent, :fn, :cc
                        )
                    """),
                    {
                        "code": eq_code,
                        "desc": ot.get("wowoEquipmentDescription") or "Autogenerated Equipment Description",
                        "cat": default_category,
                        "zone": default_zone,
                        "ent": default_entity,
                        "fn": ot.get("wowoFunction") or "AUTOGEN",
                        "cc": default_costcentre
                    }
                )
                existing_equipments.add(eq_code)

            # Check supervisor/user
            sv_code = ot.get("wowoSupervisor")
            if sv_code and sv_code not in existing_users:
                print(f"  [Self-Healing] Creating missing supervisor user: {sv_code}")
                conn.execute(
                    text("INSERT INTO dbo.coswin_user (cwcu_code, cwcu_signature, cwcu_email) VALUES (:code, :sig, :email)"),
                    {
                        "code": sv_code,
                        "sig": ot.get("wowoSupervisorDescription") or "Autogenerated Supervisor Signature",
                        "email": f"user_{sv_code}@electricite.sn"
                    }
                )
                existing_users.add(sv_code)

            # Check costcentre
            cc_code = ot.get("wowoCostcentre")
            if cc_code and cc_code not in existing_costcentres:
                print(f"  [Self-Healing] Creating missing costcentre: {cc_code}")
                conn.execute(
                    text("INSERT INTO dbo.costcentre (mdcc_code, mdcc_description) VALUES (:code, :desc)"),
                    {"code": cc_code, "desc": ot.get("wowoCostcentreDescription") or "Autogenerated Costcentre"}
                )
                existing_costcentres.add(cc_code)

            # Check entity fields
            for ent_code_key, ent_desc_key in [("wowoActionEntity", "wowoActionEntityDescription"), ("wowoRequestEntity", None)]:
                ent_code = ot.get(ent_code_key)
                if ent_code and ent_code not in existing_entities:
                    print(f"  [Self-Healing] Creating missing entity: {ent_code}")
                    desc = ot.get(ent_desc_key) if ent_desc_key else "Autogenerated Entity"
                    conn.execute(
                        text("INSERT INTO dbo.entity (chen_code, chen_description, chen_entity_type, chen_level) VALUES (:code, :desc, 'AUTOGEN', 1)"),
                        {"code": ent_code, "desc": desc or "Autogenerated Entity"}
                    )
                    existing_entities.add(ent_code)

            # Check zone
            zone_code = ot.get("wowoZone")
            if zone_code and zone_code not in existing_zones:
                print(f"  [Self-Healing] Creating missing zone: {zone_code}")
                conn.execute(
                    text("INSERT INTO dbo.zone (mdzo_code, mdzo_description) VALUES (:code, :desc)"),
                    {"code": zone_code, "desc": "Autogenerated Zone"}
                )
                existing_zones.add(zone_code)

            # Check category
            cat_code = ot.get("wowoJobClass")
            if cat_code and cat_code not in existing_categories:
                print(f"  [Self-Healing] Creating missing category (job class): {cat_code}")
                conn.execute(
                    text("INSERT INTO dbo.category (mdct_code, mdct_description) VALUES (:code, :desc)"),
                    {"code": cat_code, "desc": ot.get("wowoJobClassDescription") or "Autogenerated Category"}
                )
                existing_categories.add(cat_code)

            # Convert dates to datetime objects or None
            def parse_date(date_str):
                if not date_str:
                    return None
                try:
                    # Remove 'Z' and parse ISO format
                    return datetime.fromisoformat(date_str.replace("Z", ""))
                except:
                    return None
            
            from datetime import datetime
            sch_date = parse_date(ot.get("wowoScheduleDate"))
            tgt_date = parse_date(ot.get("wowoTargetDate"))
            start_date = parse_date(ot.get("wowoStartDate"))
            end_date = parse_date(ot.get("wowoEndDate"))

            # 2. Insert work order
            conn.execute(
                text("""
                    INSERT INTO dbo.workorder (
                        wowo_code, wowo_user_status, wowo_equipment, wowo_job, wowo_job_type, wowo_job_class,
                        wowo_priority, wowo_action_entity, wowo_request_entity, wowo_schedule_date,
                        wowo_supervisor, wowo_costcentre, wowo_target_date, wowo_start_date, wowo_end_date,
                        wowo_zone, wowo_function, wowo_feedback_note, wowo_equipment_description,
                        wowo_string1, wowo_string2, wowo_string4, mdjb_description, mdus_description,
                        wowo_action_entity_description, wowo_costcentre_description, wowo_job_class_description,
                        wowo_job_type_description, wowo_supervisor_description
                    ) VALUES (
                        :wowo_code, :wowo_user_status, :wowo_equipment, :wowo_job, :wowo_job_type, :wowo_job_class,
                        :wowo_priority, :wowo_action_entity, :wowo_request_entity, :wowo_schedule_date,
                        :wowo_supervisor, :wowo_costcentre, :wowo_target_date, :wowo_start_date, :wowo_end_date,
                        :wowo_zone, :wowo_function, :wowo_feedback_note, :wowo_equipment_description,
                        :wowo_string1, :wowo_string2, :wowo_string4, :mdjb_description, :mdus_description,
                        :wowo_action_entity_description, :wowo_costcentre_description, :wowo_job_class_description,
                        :wowo_job_type_description, :wowo_supervisor_description
                    )
                """),
                {
                    "wowo_code": code,
                    "wowo_user_status": ot.get("wowoUserStatus"),
                    "wowo_equipment": eq_code,
                    "wowo_job": ot.get("wowoJob"),
                    "wowo_job_type": ot.get("wowoJobType"),
                    "wowo_job_class": cat_code,
                    "wowo_priority": ot.get("wowoPriority"),
                    "wowo_action_entity": ot.get("wowoActionEntity"),
                    "wowo_request_entity": ot.get("wowoRequestEntity"),
                    "wowo_schedule_date": sch_date,
                    "wowo_supervisor": sv_code,
                    "wowo_costcentre": cc_code,
                    "wowo_target_date": tgt_date,
                    "wowo_start_date": start_date,
                    "wowo_end_date": end_date,
                    "wowo_zone": zone_code,
                    "wowo_function": ot.get("wowoFunction"),
                    "wowo_feedback_note": ot.get("wowoFeedbackNote"),
                    "wowo_equipment_description": ot.get("wowoEquipmentDescription"),
                    "wowo_string1": ot.get("wowoString1"),
                    "wowo_string2": ot.get("wowoString2"),
                    "wowo_string4": ot.get("wowoString4"),
                    "mdjb_description": ot.get("mdjbDescription"),
                    "mdus_description": ot.get("mdusDescription"),
                    "wowo_action_entity_description": ot.get("wowoActionEntityDescription"),
                    "wowo_costcentre_description": ot.get("wowoCostcentreDescription"),
                    "wowo_job_class_description": ot.get("wowoJobClassDescription"),
                    "wowo_job_type_description": ot.get("wowoJobTypeDescription"),
                    "wowo_supervisor_description": ot.get("wowoSupervisorDescription")
                }
            )
            
        print("Seeding validation statuses...")
        conn.execute(text("DELETE FROM dbo.workorder_validation_status"))
        validation_transitions = [
            ("OUV", "EC", "Passage en cours d'execution"),
            ("OUV", "CL", "Cloture directe"),
            ("CR", "OUV", "Approbation de creation"),
            ("EC", "CL", "Cloture apres execution"),
            ("CR", "CL", "Annulation")
        ]
        for src_status, dst_status, desc in validation_transitions:
            conn.execute(
                text("INSERT INTO dbo.workorder_validation_status (current_status, next_status, description) VALUES (:curr, :nxt, :desc)"),
                {"curr": src_status, "nxt": dst_status, "desc": desc}
            )

        print("\nSeeding summary:")
        wo_count = conn.execute(text("SELECT COUNT(*) FROM dbo.workorder")).fetchone()[0]
        status_count = conn.execute(text("SELECT COUNT(*) FROM dbo.workorder_validation_status")).fetchone()[0]
        print(f"  Work orders loaded: {wo_count}")
        print(f"  Validation statuses loaded: {status_count}")
        print("SUCCESS: SEEDING COMPLETED SUCCESSFULLY!")

except Exception as e:
    print("Error seeding work orders:", e)
    exit(1)

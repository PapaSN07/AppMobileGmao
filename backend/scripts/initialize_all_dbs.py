import os
import sys
import json
import pyodbc
import subprocess
from pathlib import Path
from dotenv import load_dotenv

# Path helper
ROOT_DIR = Path(__file__).resolve().parents[2]
BACKEND_DIR = ROOT_DIR / "backend"
sys.path.append(str(BACKEND_DIR))

# Load environment variables
load_dotenv(BACKEND_DIR / ".env.prod")

LOCAL_HOST = "localhost"
LOCAL_PORT = "1433"
LOCAL_USER = "sa"
LOCAL_PASS = "Mssql_2025@"

def get_master_conn():
    for driver in ("ODBC Driver 18 for SQL Server", "ODBC Driver 17 for SQL Server"):
        try:
            conn = pyodbc.connect(
                f"DRIVER={{{driver}}};"
                f"SERVER={LOCAL_HOST},{LOCAL_PORT};"
                f"DATABASE=master;"
                f"UID={LOCAL_USER};"
                f"PWD={LOCAL_PASS};"
                "TrustServerCertificate=yes;"
                "Encrypt=yes;",
                timeout=10,
            )
            print(f"  Connected to master database using {driver}")
            return conn
        except pyodbc.Error:
            continue
    raise RuntimeError("[ERROR] Cannot connect to SQL Server. Make sure Docker is running and the database container is started.")

def run_sql_file(conn, file_path):
    print(f"Executing SQL file: {file_path.name}")
    content = file_path.read_text(encoding="utf-8")
    
    # Remove GO statements and execute block-by-block
    cursor = conn.cursor()
    blocks = content.split("GO")
    for block in blocks:
        stmt = block.strip()
        if not stmt:
            continue
        try:
            cursor.execute(stmt)
        except Exception as e:
            # Print warning but try to continue (e.g. if table already exists or drops fail)
            if "already exists" not in str(e) and "sys.objects" not in str(e):
                print(f"  [Warning] SQL statement execution: {str(e)[:150]}")
    conn.commit()

def main():
    print("=" * 60)
    print("  AUTOMATED DATABASE INITIALIZER & SEEDER")
    print("=" * 60)
    
    try:
        conn = get_master_conn()
    except Exception as e:
        print(e)
        sys.exit(1)
        
    cursor = conn.cursor()
    cursor.execute("SET NOCOUNT ON;")
    
    # 1. Create databases
    databases = ["gmao_backend", "gmao_mobile", "coswin_mock"]
    for db in databases:
        print(f"Creating database '{db}' if not exists...")
        try:
            cursor.execute(f"IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = '{db}') CREATE DATABASE {db};")
            conn.commit()
            print(f"  Database '{db}': OK")
        except Exception as e:
            print(f"  Error creating '{db}': {e}")
            
    # 2. Run schema scripts
    sql_dir = BACKEND_DIR / "scripts" / "sql"
    
    # Local schema (gmao_backend)
    create_local_schema_path = sql_dir / "create_local_schema.sql"
    if create_local_schema_path.exists():
        run_sql_file(conn, create_local_schema_path)
    else:
        print("[Warning] create_local_schema.sql not found!")
        
    # Coswin mock schema (coswin_mock)
    create_coswin_mock_path = sql_dir / "create_coswin_mock.sql"
    if create_coswin_mock_path.exists():
        run_sql_file(conn, create_coswin_mock_path)
    else:
        print("[Warning] create_coswin_mock.sql not found!")
        
    conn.close()
    print("[SUCCESS] Databases and schemas initialized successfully!")
    
    # 3. Create SQLAlchemy tables (especially the 'users' table in gmao_mobile)
    print("\nRunning SQLAlchemy table creation...")
    try:
        from app.db.sqlalchemy.engine import create_all_tables
        # Import models so they are registered on Base/BaseClicClac metadata
        import app.models.user_model
        import app.models.equipment_model
        create_all_tables()
        print("  SQLAlchemy tables: OK")
    except Exception as e:
        print(f"  [Warning] Error running SQLAlchemy create_all_tables: {e}")
        
    # 4. Import Equipment Data into gmao_backend
    print("\nSeeding equipment data...")
    try:
        subprocess.run([sys.executable, str(BACKEND_DIR / "scripts" / "import_equipment_direct.py")], check=True)
        print("  Equipment seeding: OK")
    except Exception as e:
        print(f"  [Warning] Error seeding equipments: {e}")
        
    # 5. Copy reference data & Seed Work Orders in coswin_mock
    print("\nSeeding work orders & Coswin users...")
    try:
        # First, ensure gmao_backend has a mock coswin_user table with reference data
        # so seed_coswin_mock can copy it
        print("  Creating reference tables in gmao_backend...")
        conn_backend = pyodbc.connect(
            f"DRIVER={{ODBC Driver 17 for SQL Server}};"
            f"SERVER={LOCAL_HOST},{LOCAL_PORT};"
            f"DATABASE=gmao_backend;"
            f"UID={LOCAL_USER};"
            f"PWD={LOCAL_PASS};"
            "TrustServerCertificate=yes;"
            "Encrypt=yes;"
        )
        b_cursor = conn_backend.cursor()
        
        # Create minimal coswin_user table in gmao_backend for seeding
        b_cursor.execute("""
            IF OBJECT_ID('dbo.coswin_user', 'U') IS NULL
            CREATE TABLE dbo.coswin_user (
                pk_coswin_user INT IDENTITY(1,1) NOT NULL,
                cwcu_code VARCHAR(50) NOT NULL UNIQUE,
                cwcu_signature VARCHAR(255) NOT NULL,
                cwcu_password VARCHAR(255) NULL,
                cwcu_email VARCHAR(255) NULL,
                cwcu_entity VARCHAR(50) NULL,
                cwcu_preferred_group VARCHAR(50) NULL,
                cwcu_url_image VARCHAR(255) NULL,
                cwcu_is_absent INT NULL
            );
        """)
        
        # Insert default supervisor user in gmao_backend
        b_cursor.execute("""
            IF NOT EXISTS (SELECT 1 FROM dbo.coswin_user WHERE cwcu_code = '5286')
            INSERT INTO dbo.coswin_user (cwcu_code, cwcu_signature, cwcu_email, cwcu_preferred_group)
            VALUES ('5286', 'ERIC DASYLVA CARDOZO', 'eric.cardozo@electricite.sn', 'ADMIN');
        """)
        conn_backend.commit()
        conn_backend.close()
        
        subprocess.run([sys.executable, str(BACKEND_DIR / "scripts" / "seed_coswin_mock.py")], check=True)
        print("  Coswin mock seeding: OK")
    except Exception as e:
        print(f"  [Warning] Error seeding Coswin mock: {e}")
        
    print("\n[SUCCESS] Database setup complete! You can now run your backend and frontend.")

if __name__ == "__main__":
    main()

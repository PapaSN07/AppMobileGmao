import pyodbc

def check_db(db_name):
    print(f"\n--- Checking Database: {db_name} ---")
    try:
        conn = pyodbc.connect(
            "DRIVER={ODBC Driver 17 for SQL Server};"
            "SERVER=localhost,1433;"
            f"DATABASE={db_name};"
            "UID=sa;"
            "PWD=Mssql_2025@;"
            "TrustServerCertificate=yes;"
            "Encrypt=yes;",
            timeout=5
        )
        cursor = conn.cursor()
        
        cursor.execute("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'")
        tables = [row[0] for row in cursor.fetchall()]
        print(f"Tables in {db_name}: {tables}")
        
        for table in tables:
            if "user" in table.lower():
                print(f"\nTable: {table}")
                cursor.execute(f"SELECT * FROM {table}")
                columns = [column[0] for column in cursor.description]
                print(f"Columns: {columns}")
                rows = cursor.fetchall()
                print(f"Found {len(rows)} users.")
                for row in rows[:10]: # show first 10
                    row_dict = dict(zip(columns, row))
                    if 'password' in row_dict and row_dict['password']:
                        row_dict['password'] = row_dict['password'][:15] + "..."
                    if 'cwcu_password' in row_dict and row_dict['cwcu_password']:
                        row_dict['cwcu_password'] = row_dict['cwcu_password'][:15] + "..."
                    print(row_dict)
        conn.close()
    except Exception as e:
        print(f"Error checking {db_name}: {e}")

check_db("gmao_backend")
check_db("gmao_mobile")
check_db("coswin_mock")

import json
import subprocess
import pyodbc
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
JSON_PATH = ROOT / "scripts" / "data_extracted" / "equipment_latest.json"
SQL_PATH = ROOT / "scripts" / "sql" / "import_equipment_from_json.sql"


def pick(row, *keys):
    for key in keys:
        if key in row and row.get(key) not in (None, ""):
            return row.get(key)
    return None


def q(value):
    if value is None:
        return "NULL"
    text = str(value).replace("'", "''")
    return "N'" + text + "'"


def num(value):
    if value is None or str(value).strip() == "":
        return "NULL"
    try:
        return str(float(value))
    except Exception:
        return "NULL"


def main():
    data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
    lines = [
        "USE gmao_backend;",
        "GO",
        "SET NOCOUNT ON;",
        "GO",
        "SET IDENTITY_INSERT dbo.equipment ON;",
    ]

    count = 0
    for row in data:
        pk = pick(row, "pk_equipment", "timestamp", "PK_EQUIPMENT", "TIMESTAMP")
        if pk is None:
            continue

        parent = pick(row, "ereq_parent_equipment", "EREQ_PARENT_EQUIPMENT")
        code = pick(row, "ereq_code", "EREQ_CODE")
        category = pick(row, "ereq_category", "EREQ_CATEGORY")
        zone = pick(row, "ereq_zone", "EREQ_ZONE")
        entity = pick(row, "ereq_entity", "EREQ_ENTITY")
        function_ = pick(row, "ereq_function", "EREQ_FUNCTION")
        costcentre = pick(row, "ereq_costcentre", "EREQ_COSTCENTRE")
        description = pick(row, "ereq_description", "EREQ_DESCRIPTION")
        longitude = pick(row, "ereq_longitude", "EREQ_LONGITUDE")
        latitude = pick(row, "ereq_latitude", "EREQ_LATITUDE")
        feeder = pick(row, "feeder_code", "ereq_string2", "EREQ_STRING2")
        barcode = pick(row, "ereq_bar_code", "EREQ_BAR_CODE")
        creation_date = pick(row, "ereq_creation_date", "EREQ_CREATION_DATE")
        costcentre_description = pick(row, "costcentre_description")
        creation_sql = "NULL" if creation_date in (None, "") else q(creation_date)

        lines.append(
            "IF NOT EXISTS (SELECT 1 FROM dbo.equipment WHERE pk_equipment = {pk}) "
            "INSERT INTO dbo.equipment ("
            "pk_equipment, ereq_parent_equipment, ereq_code, ereq_category, ereq_zone, ereq_entity, "
            "ereq_function, ereq_costcentre, ereq_description, ereq_longitude, ereq_latitude, "
            "ereq_string2, ereq_bar_code, ereq_creation_date"
            ") VALUES ("
            "{pk}, {parent}, {code}, {category}, {zone}, {entity}, {function_}, {costcentre}, "
            "{description}, {longitude}, {latitude}, {feeder}, {barcode}, {creation_date}"
            ");".format(
                pk=int(pk),
                parent=q(parent),
                code=q(code),
                category=q(category),
                zone=q(zone),
                entity=q(entity),
                function_=q(function_),
                costcentre=q(costcentre),
                description=q(description),
                longitude=num(longitude),
                latitude=num(latitude),
                feeder=q(feeder),
                barcode=q(barcode),
                creation_date=creation_sql,
            )
        )
        count += 1

    lines.append("SET IDENTITY_INSERT dbo.equipment OFF;")
    lines.append("GO")
    SQL_PATH.write_text("\n".join(lines), encoding="utf-8")
    print(f"SQL generated: {SQL_PATH} ({count} rows)")

    # Execute the SQL lines directly on the local native SQL Server via pyodbc
    print("Executing SQL statements on local SQL Server...")
    conn = None
    for driver in ("ODBC Driver 18 for SQL Server", "ODBC Driver 17 for SQL Server"):
        try:
            conn = pyodbc.connect(
                f"DRIVER={{{driver}}};"
                "SERVER=localhost,1433;"
                "DATABASE=gmao_backend;"
                "UID=sa;"
                "PWD=Mssql_2025@;"
                "TrustServerCertificate=yes;"
                "Encrypt=yes;",
                timeout=10
            )
            print(f"  Connected using {driver}")
            break
        except Exception as conn_err:
            print(f"  Connection error with {driver}: {conn_err}")
            continue
            
    if conn is None:
        raise RuntimeError("Could not connect to SQL Server to import equipments.")
        
    try:
        cursor = conn.cursor()
        for sql_line in lines:
            sql_line = sql_line.strip()
            if not sql_line or sql_line == "GO" or sql_line.startswith("USE "):
                continue
            cursor.execute(sql_line)
        conn.commit()
        conn.close()
        print("Import equipment completed successfully via pyodbc.")
    except Exception as e:
        print(f"Error executing SQL via pyodbc: {e}")
        raise


if __name__ == "__main__":
    main()

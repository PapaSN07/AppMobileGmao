import json
import subprocess
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
        "USE gmao_local;",
        "GO",
        "SET NOCOUNT ON;",
        "GO",
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
            "IF NOT EXISTS (SELECT 1 FROM dbo.equipment WHERE timestamp = {pk}) "
            "INSERT INTO dbo.equipment ("
            "timestamp, ereq_parent_equipment, ereq_code, ereq_category, ereq_zone, ereq_entity, "
            "ereq_function, ereq_costcentre, ereq_description, ereq_longitude, ereq_latitude, "
            "ereq_string2, ereq_bar_code, ereq_creation_date, costcentre_description"
            ") VALUES ("
            "{pk}, {parent}, {code}, {category}, {zone}, {entity}, {function_}, {costcentre}, "
            "{description}, {longitude}, {latitude}, {feeder}, {barcode}, {creation_date}, {costcentre_description}"
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
                costcentre_description=q(costcentre_description),
            )
        )
        count += 1

    lines.append("GO")
    SQL_PATH.write_text("\n".join(lines), encoding="utf-8")
    print(f"SQL generated: {SQL_PATH} ({count} rows)")

    cmd = [
        "docker",
        "exec",
        "gmao_sqlserver_local",
        "/opt/mssql-tools18/bin/sqlcmd",
        "-S",
        "localhost",
        "-U",
        "sa",
        "-P",
        "GmaoLocal456#",
        "-d",
        "gmao_local",
        "-i",
        "/scripts/sql/import_equipment_from_json.sql",
        "-No",
    ]
    subprocess.run(cmd, check=True)
    print("Import equipment termine.")


if __name__ == "__main__":
    main()

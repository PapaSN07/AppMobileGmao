import requests
from requests.auth import HTTPDigestAuth
import json

base_url = "http://10.101.1.102:8083/ws/rest/workorders"
auth = HTTPDigestAuth("coswinws", "supervisor")
common_params = {
    "dataSource": "Coswin",
    "cwUser": "coswinws",
}

log_file_path = "coswin_api_diagnostic_v9.txt"

def log(message):
    print(message)
    with open(log_file_path, "a", encoding="utf-8") as f:
        f.write(message + "\n")

# Clear previous log
with open(log_file_path, "w", encoding="utf-8") as f:
    f.write("=== COSWIN API DIAGNOSTIC V9 LOG ===\n")

log("Starting Coswin API diagnostics V9...")

# Since the user confirmed the operator is 'equals', let's test if we can target wowoRequestEntity.
tests = [
    {
        "name": "filterColumn=wowoRequestEntity with equals",
        "params": {"filterColumn": "wowoRequestEntity", "filterOperator": "equals", "filterOperand1": "DTAE", "usePagination": "true"}
    },
    {
        "name": "filterField=wowoRequestEntity with equals",
        "params": {"filterField": "wowoRequestEntity", "filterOperator": "equals", "filterOperand1": "DTAE", "usePagination": "true"}
    },
    {
        "name": "field=wowoRequestEntity with equals",
        "params": {"field": "wowoRequestEntity", "filterOperator": "equals", "filterOperand1": "DTAE", "usePagination": "true"}
    },
    {
        "name": "column=wowoRequestEntity with equals",
        "params": {"column": "wowoRequestEntity", "filterOperator": "equals", "filterOperand1": "DTAE", "usePagination": "true"}
    },
    {
        "name": "filterColumn1=wowoRequestEntity with equals",
        "params": {"filterColumn1": "wowoRequestEntity", "filterOperator1": "equals", "filterOperand1_1": "DTAE", "usePagination": "true"}
    },
    {
        "name": "filterColumn=wowoRequestEntity and filterOperator=equals and filterOperand1=DTAE",
        "params": {"filterColumn": "wowoRequestEntity", "filterOperator": "equals", "filterOperand1": "DTAE", "usePagination": "true"}
    },
    # Let's also try with wowoSupervisor
    {
        "name": "filterColumn=wowoSupervisor with equals",
        "params": {"filterColumn": "wowoSupervisor", "filterOperator": "equals", "filterOperand1": "6732", "usePagination": "true"}
    },
]

for i, test in enumerate(tests):
    log(f"\n--- TEST {i+1}: {test['name']} ---")
    params = {**common_params, **test["params"]}
    try:
        r = requests.get(base_url, params=params, auth=auth, timeout=10)
        log(f"Status: {r.status_code}")
        if r.status_code == 200:
            data = r.json()
            workorders = data.get("list", {}).get("workorderfind", [])
            log(f"Success! Returned {len(workorders)} workorders.")
            if workorders:
                log(f"First workorder: code={workorders[0].get('wowoCode')}, entity={workorders[0].get('wowoRequestEntity')}, supervisor={workorders[0].get('wowoSupervisor')}")
                entities = set(wo.get('wowoRequestEntity') for wo in workorders if wo.get('wowoRequestEntity'))
                log(f"Unique entities in result: {entities}")
        else:
            log(f"Response: {r.text[:300]}")
    except Exception as e:
        log(f"Error: {e}")

log("\nDiagnostics V9 complete. Output saved to coswin_api_diagnostic_v9.txt")

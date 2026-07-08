import requests
from requests.auth import HTTPDigestAuth
import json

base_url = "http://10.101.1.102:8083/ws/rest/workorders"
auth = HTTPDigestAuth("coswinws", "supervisor")
common_params = {
    "dataSource": "Coswin",
    "cwUser": "coswinws",
}

log_file_path = "coswin_api_diagnostic_v2.txt"

def log(message):
    print(message)
    with open(log_file_path, "a", encoding="utf-8") as f:
        f.write(message + "\n")

# Clear previous log
with open(log_file_path, "w", encoding="utf-8") as f:
    f.write("=== COSWIN API DIAGNOSTIC V2 LOG ===\n")

log("Starting Coswin API diagnostics V2...")

# We know filterOperator=different&filterOperand1=0 works.
# Let's see if we can add other parameters to filter.
tests = [
    # 1. Combining working operator with direct field names
    {
        "name": "Direct field wowoRequestEntity with working operator",
        "params": {"filterOperator": "different", "filterOperand1": "0", "wowoRequestEntity": "DTAE", "usePagination": "true"}
    },
    {
        "name": "Direct field requestEntity with working operator",
        "params": {"filterOperator": "different", "filterOperand1": "0", "requestEntity": "DTAE", "usePagination": "true"}
    },
    {
        "name": "Direct field wowoActionEntity with working operator",
        "params": {"filterOperator": "different", "filterOperand1": "0", "wowoActionEntity": "DTAE", "usePagination": "true"}
    },
    {
        "name": "Direct field actionEntity with working operator",
        "params": {"filterOperator": "different", "filterOperand1": "0", "actionEntity": "DTAE", "usePagination": "true"}
    },
    {
        "name": "Direct field wowoSupervisor with working operator",
        "params": {"filterOperator": "different", "filterOperand1": "0", "wowoSupervisor": "6732", "usePagination": "true"}
    },
    
    # 2. Testing different parameter names for specifying the column
    {
        "name": "filterField parameter",
        "params": {"filterField": "wowoRequestEntity", "filterOperator": "equal", "filterOperand1": "DTAE", "usePagination": "true"}
    },
    {
        "name": "field parameter",
        "params": {"field": "wowoRequestEntity", "filterOperator": "equal", "filterOperand1": "DTAE", "usePagination": "true"}
    },
    {
        "name": "column parameter",
        "params": {"column": "wowoRequestEntity", "filterOperator": "equal", "filterOperand1": "DTAE", "usePagination": "true"}
    },
    {
        "name": "attribute parameter",
        "params": {"attribute": "wowoRequestEntity", "filterOperator": "equal", "filterOperand1": "DTAE", "usePagination": "true"}
    },
    {
        "name": "propertyName parameter",
        "params": {"propertyName": "wowoRequestEntity", "filterOperator": "equal", "filterOperand1": "DTAE", "usePagination": "true"}
    },
    
    # 3. Testing filterOperator1 / filterOperand1_1 / filterColumn1
    {
        "name": "filterColumn1 with filterOperator1 and filterOperand1_1",
        "params": {"filterColumn1": "wowoRequestEntity", "filterOperator1": "equal", "filterOperand1_1": "DTAE", "usePagination": "true"}
    },
    {
        "name": "filterColumn1 with filterOperator and filterOperand1",
        "params": {"filterColumn1": "wowoRequestEntity", "filterOperator": "equal", "filterOperand1": "DTAE", "usePagination": "true"}
    },
]

for i, test in enumerate(tests):
    log(f"\n--- TEST {i+1}: {test['name']} ---")
    params = {**common_params, **test["params"]}
    try:
        r = requests.get(base_url, params=params, auth=auth, timeout=15)
        log(f"Status: {r.status_code}")
        if r.status_code == 200:
            workorders = r.json().get("list", {}).get("workorderfind", [])
            log(f"Success! Returned {len(workorders)} workorders.")
            if workorders:
                log(f"Sample matches: code={workorders[0].get('wowoCode')}, entity={workorders[0].get('wowoRequestEntity')}")
                # Print unique entities to see if it actually filtered!
                entities = set(wo.get('wowoRequestEntity') for wo in workorders)
                log(f"Unique entities in result: {entities}")
        else:
            log(f"Response (truncated): {r.text[:300]}")
    except Exception as e:
        log(f"Error: {e}")

log("\nDiagnostics V2 complete. Output saved to coswin_api_diagnostic_v2.txt")

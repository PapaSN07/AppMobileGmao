import requests
from requests.auth import HTTPDigestAuth

base_url = "http://10.101.1.102:8083/ws/rest/workorders"
auth = HTTPDigestAuth("coswinws", "supervisor")
common_params = {
    "dataSource": "Coswin",
    "cwUser": "coswinws",
}

log_file_path = "coswin_api_diagnostic_v10.txt"

def log(message):
    print(message)
    with open(log_file_path, "a", encoding="utf-8") as f:
        f.write(message + "\n")

# Clear previous log
with open(log_file_path, "w", encoding="utf-8") as f:
    f.write("=== COSWIN API DIAGNOSTIC V10 LOG ===\n")

log("Starting Coswin API diagnostics V10...")

# We will test different column names with 'equals'
columns = [
    "wowoActionEntity",
    "WOWO_REQUEST_ENTITY",
    "WOWO_ACTION_ENTITY",
    "wowo_request_entity",
    "wowo_action_entity",
    "wowoCostcentre",
    "wowoUserStatus",
    "wowoEquipment",
    "wowoJob",
    "wowoPriority",
]

for col in columns:
    log(f"\n--- TESTING COLUMN: {col} ---")
    params = {
        **common_params,
        "filterColumn": col,
        "filterOperator": "equals",
        "filterOperand1": "DTAE" if "Entity" in col or "ENTITY" in col or "entity" in col else "2025248525", # fallback value
        "usePagination": "true"
    }
    
    # Adjust operand for testing other fields
    if col == "wowoUserStatus":
        params["filterOperand1"] = "AY"
    elif col == "wowoEquipment":
        params["filterOperand1"] = "UED/R"
    elif col == "wowoCostcentre":
        params["filterOperand1"] = "DD305"

    try:
        r = requests.get(base_url, params=params, auth=auth, timeout=10)
        log(f"Status: {r.status_code}")
        if r.status_code == 200:
            data = r.json()
            workorders = data.get("list", {}).get("workorderfind", [])
            log(f"Success! Returned {len(workorders)} workorders.")
            if workorders:
                log(f"First match: code={workorders[0].get('wowoCode')}, entity={workorders[0].get('wowoRequestEntity')}, status={workorders[0].get('wowoUserStatus')}, supervisor={workorders[0].get('wowoSupervisor')}")
                entities = set(wo.get('wowoRequestEntity') for wo in workorders if wo.get('wowoRequestEntity'))
                log(f"Unique entities in result: {entities}")
        else:
            log(f"Response: {r.text[:300]}")
    except Exception as e:
        log(f"Error: {e}")

log("\nDiagnostics V10 complete. Output saved to coswin_api_diagnostic_v10.txt")

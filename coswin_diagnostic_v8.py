import requests
from requests.auth import HTTPDigestAuth

base_url = "http://10.101.1.102:8083/ws/rest/workorders"
auth = HTTPDigestAuth("coswinws", "supervisor")
common_params = {
    "dataSource": "Coswin",
    "cwUser": "coswinws",
}

log_file_path = "coswin_api_diagnostic_v8.txt"

def log(message):
    print(message)
    with open(log_file_path, "a", encoding="utf-8") as f:
        f.write(message + "\n")

# Clear previous log
with open(log_file_path, "w", encoding="utf-8") as f:
    f.write("=== COSWIN API DIAGNOSTIC V8 LOG ===\n")

log("Starting Coswin API diagnostics V8...")

# We will test different equality operator names on wowoCode
operators = ["equals", "eq", "like", "same", "is", "match", "matches", "equalto", "equal_to", "identical"]

for op in operators:
    log(f"\n--- TESTING OPERATOR: {op} ---")
    params = {**common_params, "filterOperator": op, "filterOperand1": "2025248525", "usePagination": "true"}
    try:
        r = requests.get(base_url, params=params, auth=auth, timeout=10)
        log(f"Status: {r.status_code}")
        if r.status_code == 200:
            data = r.json()
            workorders = data.get("list", {}).get("workorderfind", [])
            log(f"Success! Returned {len(workorders)} workorders.")
            if workorders:
                log(f"Matched code: {workorders[0].get('wowoCode')}")
        else:
            log(f"Response: {r.text[:300]}")
    except Exception as e:
        log(f"Error: {e}")

log("\nDiagnostics V8 complete. Output saved to coswin_api_diagnostic_v8.txt")

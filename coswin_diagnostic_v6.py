import requests
from requests.auth import HTTPDigestAuth

base_url = "http://10.101.1.102:8083/ws/rest/workorders"
auth = HTTPDigestAuth("coswinws", "supervisor")
common_params = {
    "dataSource": "Coswin",
    "cwUser": "coswinws",
}

log_file_path = "coswin_api_diagnostic_v6.txt"

def log(message):
    print(message)
    with open(log_file_path, "a", encoding="utf-8") as f:
        f.write(message + "\n")

# Clear previous log
with open(log_file_path, "w", encoding="utf-8") as f:
    f.write("=== COSWIN API DIAGNOSTIC V6 LOG ===\n")

log("Starting Coswin API diagnostics V6...")

operators = [
    # 1. Test standard 'equal' with a known code from V1 to verify if it works
    {"name": "equal with known code", "params": {"filterOperator": "equal", "filterOperand1": "2025248525", "usePagination": "true"}},
    
    # 2. Test different comparison operators for greater than 2025000000
    {"name": "greaterOrEqual with 2025000000", "params": {"filterOperator": "greaterOrEqual", "filterOperand1": "2025000000", "usePagination": "true"}},
    {"name": "greater with 2025000000", "params": {"filterOperator": "greater", "filterOperand1": "2025000000", "usePagination": "true"}},
    {"name": "ge with 2025000000", "params": {"filterOperator": "ge", "filterOperand1": "2025000000", "usePagination": "true"}},
    {"name": "gt with 2025000000", "params": {"filterOperator": "gt", "filterOperand1": "2025000000", "usePagination": "true"}},
    {"name": "GE with 2025000000", "params": {"filterOperator": "GE", "filterOperand1": "2025000000", "usePagination": "true"}},
    {"name": "GT with 2025000000", "params": {"filterOperator": "GT", "filterOperand1": "2025000000", "usePagination": "true"}},
    {"name": "greater_or_equal with 2025000000", "params": {"filterOperator": "greater_or_equal", "filterOperand1": "2025000000", "usePagination": "true"}},
]

for i, test in enumerate(operators):
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
                log(f"First workorder: code={workorders[0].get('wowoCode')}, date={workorders[0].get('wowoReportDate')}, entity={workorders[0].get('wowoRequestEntity')}")
        else:
            log(f"Response (truncated): {r.text[:300]}")
    except Exception as e:
        log(f"Error: {e}")

log("\nDiagnostics V6 complete. Output saved to coswin_api_diagnostic_v6.txt")

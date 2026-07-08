import requests
from requests.auth import HTTPDigestAuth

base_url = "http://10.101.1.102:8083/ws/rest/workorders"
auth = HTTPDigestAuth("coswinws", "supervisor")
common_params = {
    "dataSource": "Coswin",
    "cwUser": "coswinws",
}

log_file_path = "coswin_api_diagnostic_v5.txt"

def log(message):
    print(message)
    with open(log_file_path, "a", encoding="utf-8") as f:
        f.write(message + "\n")

# Clear previous log
with open(log_file_path, "w", encoding="utf-8") as f:
    f.write("=== COSWIN API DIAGNOSTIC V5 LOG ===\n")

log("Starting Coswin API diagnostics V5...")

# We will test different sorting parameters.
# If a sort works, the first workorder code returned should be a recent one (e.g. 2025... or 2026...)
# instead of the oldest one (e.g. 2018001702).
tests = [
    {
        "name": "No sorting (baseline)",
        "params": {"filterOperator": "different", "filterOperand1": "0", "usePagination": "true"}
    },
    {
        "name": "orderBy=wowoCode DESC",
        "params": {"filterOperator": "different", "filterOperand1": "0", "orderBy": "wowoCode DESC", "usePagination": "true"}
    },
    {
        "name": "orderBy=wowoCode desc",
        "params": {"filterOperator": "different", "filterOperand1": "0", "orderBy": "wowoCode desc", "usePagination": "true"}
    },
    {
        "name": "sort=-wowoCode",
        "params": {"filterOperator": "different", "filterOperand1": "0", "sort": "-wowoCode", "usePagination": "true"}
    },
    {
        "name": "sort=wowoCode,desc",
        "params": {"filterOperator": "different", "filterOperand1": "0", "sort": "wowoCode,desc", "usePagination": "true"}
    },
    {
        "name": "sortColumn=wowoCode and sortOperator=desc",
        "params": {"filterOperator": "different", "filterOperand1": "0", "sortColumn": "wowoCode", "sortOperator": "desc", "usePagination": "true"}
    },
    {
        "name": "sortColumn=wowoCode and sortOperator=DESC",
        "params": {"filterOperator": "different", "filterOperand1": "0", "sortColumn": "wowoCode", "sortOperator": "DESC", "usePagination": "true"}
    },
    {
        "name": "orderBy=wowoReportDate DESC",
        "params": {"filterOperator": "different", "filterOperand1": "0", "orderBy": "wowoReportDate DESC", "usePagination": "true"}
    },
    {
        "name": "orderBy=wowoReportDate desc",
        "params": {"filterOperator": "different", "filterOperand1": "0", "orderBy": "wowoReportDate desc", "usePagination": "true"}
    },
]

for i, test in enumerate(tests):
    log(f"\n--- TEST {i+1}: {test['name']} ---")
    params = {**common_params, **test["params"]}
    try:
        r = requests.get(base_url, params=params, auth=auth, timeout=15)
        log(f"Status: {r.status_code}")
        if r.status_code == 200:
            data = r.json()
            workorders = data.get("list", {}).get("workorderfind", [])
            log(f"Success! Returned {len(workorders)} workorders.")
            if workorders:
                log(f"First workorder: code={workorders[0].get('wowoCode')}, date={workorders[0].get('wowoReportDate')}, entity={workorders[0].get('wowoRequestEntity')}")
                log(f"Last workorder: code={workorders[-1].get('wowoCode')}, date={workorders[-1].get('wowoReportDate')}, entity={workorders[-1].get('wowoRequestEntity')}")
        else:
            log(f"Response (truncated): {r.text[:300]}")
    except Exception as e:
        log(f"Error: {e}")

log("\nDiagnostics V5 complete. Output saved to coswin_api_diagnostic_v5.txt")

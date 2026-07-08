import requests
from requests.auth import HTTPDigestAuth

base_url = "http://10.101.1.102:8083/ws/rest/workorders"
auth = HTTPDigestAuth("coswinws", "supervisor")
common_params = {
    "dataSource": "Coswin",
    "cwUser": "coswinws",
}

direct_proxies = {
    "http": None,
    "https": None,
}

log_file_path = "coswin_api_diagnostic_v12.txt"

def log(message):
    print(message)
    with open(log_file_path, "a", encoding="utf-8") as f:
        f.write(message + "\n")

# Clear previous log
with open(log_file_path, "w", encoding="utf-8") as f:
    f.write("=== COSWIN API DIAGNOSTIC V12 LOG ===\n")

log("Starting Coswin API diagnostics V12 (Bypassing Proxy)...")

columns = [
    "wowoReqEntity",
    "wowoActEntity",
    "wowoRequest",
    "wowoEntity",
    "wowoCostCentre",
    "wowoService",
    "wowoSection",
    "wowoDepartment",
    "wowoRespEntity",
    "wowoResponsibleEntity",
]

for col in columns:
    log(f"\n--- TESTING COLUMN: {col} ---")
    params = {
        **common_params,
        "filterColumn": col,
        "filterOperator": "equals",
        "filterOperand1": "DTAE",
        "usePagination": "true"
    }
    
    try:
        r = requests.get(base_url, params=params, auth=auth, proxies=direct_proxies, timeout=10)
        log(f"Status: {r.status_code}")
        if r.status_code == 200:
            data = r.json()
            workorders = data.get("list", {}).get("workorderfind", [])
            log(f"Success! Returned {len(workorders)} workorders.")
            if workorders:
                log(f"First match: code={workorders[0].get('wowoCode')}, entity={workorders[0].get('wowoRequestEntity')}")
        else:
            log(f"Response: {r.text[:300]}")
    except Exception as e:
        log(f"Error: {e}")

log("\nDiagnostics V12 complete. Output saved to coswin_api_diagnostic_v12.txt")

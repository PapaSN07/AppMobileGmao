import requests
from requests.auth import HTTPDigestAuth
import json
import sys

base_url = "http://10.101.1.102:8083/ws/rest/workorders"
auth = HTTPDigestAuth("coswinws", "supervisor")
common_params = {
    "dataSource": "Coswin",
    "cwUser": "coswinws",
}

log_file_path = "coswin_api_diagnostic.txt"

def log(message):
    print(message)
    with open(log_file_path, "a", encoding="utf-8") as f:
        f.write(message + "\n")

# Clear previous log
with open(log_file_path, "w", encoding="utf-8") as f:
    f.write("=== COSWIN API DIAGNOSTIC LOG ===\n")

log("Starting Coswin API diagnostics...")

# Test 0: Basic GET (pagination enabled)
log("\n--- TEST 0: Fetching page 1 (5 items) ---")
params = {**common_params, "usePagination": "true", "limit": 5}
try:
    r = requests.get(base_url, params=params, auth=auth, timeout=15)
    log(f"Status: {r.status_code}")
    if r.status_code == 200:
        data = r.json()
        workorders = data.get("list", {}).get("workorderfind", [])
        log(f"Success! Fetched {len(workorders)} workorders.")
        if workorders:
            log(f"Keys in workorder: {list(workorders[0].keys())}")
            log(f"Sample values of wowoRequestEntity: {[wo.get('wowoRequestEntity') for wo in workorders]}")
            log(f"Sample values of wowoActionEntity: {[wo.get('wowoActionEntity') for wo in workorders]}")
            log(f"Sample values of wowoSupervisor: {[wo.get('wowoSupervisor') for wo in workorders]}")
            log(f"Sample values of wowoCode: {[wo.get('wowoCode') for wo in workorders]}")
except Exception as e:
    log(f"Error in Test 0: {e}")

# Test 1: Fetching specific known OT
log("\n--- TEST 1: Fetching detail of OT 2025248525 ---")
try:
    r = requests.get(f"{base_url}/2025248525", params=common_params, auth=auth, timeout=15)
    log(f"Status: {r.status_code}")
    if r.status_code == 200:
        log("Success! Details fetched.")
        log(json.dumps(r.json(), indent=2)[:1000])
except Exception as e:
    log(f"Error in Test 1: {e}")

# Try different filtering syntaxes for requestEntity = DTAE
filter_tests = [
    # Column filter context variations
    {"name": "columnFilterContext as query string", "params": {"filterOperator": "different", "filterOperand1": "0", "columnFilterContext": "wowoRequestEntity=DTAE", "usePagination": "true"}},
    {"name": "columnFilterContext as json string", "params": {"filterOperator": "different", "filterOperand1": "0", "columnFilterContext": json.dumps({"wowoRequestEntity": "DTAE"}), "usePagination": "true"}},
    {"name": "columnFilterContext with colon", "params": {"filterOperator": "different", "filterOperand1": "0", "columnFilterContext": "wowoRequestEntity:DTAE", "usePagination": "true"}},
    
    # Query parameters
    {"name": "Direct query param: wowoRequestEntity=DTAE", "params": {"wowoRequestEntity": "DTAE", "usePagination": "true"}},
    {"name": "Direct query param: requestEntity=DTAE", "params": {"requestEntity": "DTAE", "usePagination": "true"}},
    
    # Where parameter
    {"name": "where=wowoRequestEntity='DTAE'", "params": {"where": "wowoRequestEntity='DTAE'", "usePagination": "true"}},
    {"name": "whereClause=wowoRequestEntity='DTAE'", "params": {"whereClause": "wowoRequestEntity='DTAE'", "usePagination": "true"}},
    
    # filter operator/column variation
    {"name": "filterColumn syntax", "params": {"filterColumn": "wowoRequestEntity", "filterOperator": "equal", "filterOperand1": "DTAE", "usePagination": "true"}},
    {"name": "filterColumn1 syntax", "params": {"filterColumn1": "wowoRequestEntity", "filterOperator1": "equal", "filterOperand1_1": "DTAE", "usePagination": "true"}},
    
    # filter syntax
    {"name": "filter=wowoRequestEntity eq 'DTAE'", "params": {"filter": "wowoRequestEntity eq 'DTAE'", "usePagination": "true"}},
]

for i, test in enumerate(filter_tests):
    log(f"\n--- FILTER TEST {i+2}: {test['name']} ---")
    params = {**common_params, **test["params"]}
    try:
        r = requests.get(base_url, params=params, auth=auth, timeout=10)
        log(f"Status: {r.status_code}")
        if r.status_code == 200:
            workorders = r.json().get("list", {}).get("workorderfind", [])
            log(f"Success! Returned {len(workorders)} workorders.")
            if workorders:
                log(f"Sample matches: code={workorders[0].get('wowoCode')}, entity={workorders[0].get('wowoRequestEntity')}")
        else:
            log(f"Response (truncated): {r.text[:300]}")
    except Exception as e:
        log(f"Error: {e}")

log("\nDiagnostics complete. Output saved to coswin_api_diagnostic.txt")

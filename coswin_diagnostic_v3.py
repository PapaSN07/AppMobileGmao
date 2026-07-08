import requests
from requests.auth import HTTPDigestAuth

base_url = "http://10.101.1.102:8083/ws/rest/workorders"
auth = HTTPDigestAuth("coswinws", "supervisor")
common_params = {
    "dataSource": "Coswin",
    "cwUser": "coswinws",
}

log_file_path = "coswin_api_diagnostic_v3.txt"

def log(message):
    print(message)
    with open(log_file_path, "a", encoding="utf-8") as f:
        f.write(message + "\n")

# Clear previous log
with open(log_file_path, "w", encoding="utf-8") as f:
    f.write("=== COSWIN API DIAGNOSTIC V3 LOG ===\n")

log("Starting Coswin API diagnostics V3...")

tests = [
    # 1. Combining where / whereClause with working operator
    {
        "name": "where with working operator",
        "params": {"filterOperator": "different", "filterOperand1": "0", "where": "wowoRequestEntity='DTAE'", "usePagination": "true"}
    },
    {
        "name": "where Clause with working operator",
        "params": {"filterOperator": "different", "filterOperand1": "0", "whereClause": "wowoRequestEntity='DTAE'", "usePagination": "true"}
    },
    {
        "name": "where with wowoRequestEntity=DTAE (no quotes)",
        "params": {"filterOperator": "different", "filterOperand1": "0", "where": "wowoRequestEntity=DTAE", "usePagination": "true"}
    },
    
    # 2. Testing findSimple endpoint
    {
        "name": "findSimple basic",
        "url": f"{base_url}/findSimple",
        "params": {"usePagination": "true"}
    },
    {
        "name": "findSimple with filterOperator",
        "url": f"{base_url}/findSimple",
        "params": {"filterOperator": "different", "filterOperand1": "0", "usePagination": "true"}
    },
    {
        "name": "findSimple with where clause",
        "url": f"{base_url}/findSimple",
        "params": {"filterOperator": "different", "filterOperand1": "0", "where": "wowoRequestEntity='DTAE'", "usePagination": "true"}
    },
]

for i, test in enumerate(tests):
    log(f"\n--- TEST {i+1}: {test['name']} ---")
    url = test.get("url", base_url)
    params = {**common_params, **test["params"]}
    try:
        r = requests.get(url, params=params, auth=auth, timeout=15)
        log(f"Status: {r.status_code}")
        if r.status_code == 200:
            data = r.json()
            # findSimple structure might be list -> workorderfind or list -> simplefind
            workorders = data.get("list", {}).get("workorderfind", []) or data.get("list", {}).get("workordersimplefind", []) or data.get("list", {}).get("simplefind", [])
            if not workorders and isinstance(data, dict) and "list" in data:
                # print first-level list keys
                log(f"List keys: {list(data['list'].keys())}")
                first_key = list(data['list'].keys())[0]
                workorders = data['list'][first_key]
                
            log(f"Success! Returned {len(workorders)} workorders.")
            if workorders and len(workorders) > 0:
                log(f"Sample matches: keys={list(workorders[0].keys())}")
                if "wowoRequestEntity" in workorders[0]:
                    log(f"Sample matches: code={workorders[0].get('wowoCode')}, entity={workorders[0].get('wowoRequestEntity')}")
                    entities = set(wo.get('wowoRequestEntity') for wo in workorders if wo.get('wowoRequestEntity'))
                    log(f"Unique entities in result: {entities}")
        else:
            log(f"Response (truncated): {r.text[:300]}")
    except Exception as e:
        log(f"Error: {e}")

log("\nDiagnostics V3 complete. Output saved to coswin_api_diagnostic_v3.txt")

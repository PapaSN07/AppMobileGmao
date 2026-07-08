import requests
from requests.auth import HTTPDigestAuth
import time

base_url = "http://10.101.1.102:8083/ws/rest/workorders"
auth = HTTPDigestAuth("coswinws", "supervisor")
common_params = {
    "dataSource": "Coswin",
    "cwUser": "coswinws",
}

log_file_path = "coswin_api_diagnostic_v7.txt"

def log(message):
    print(message)
    with open(log_file_path, "a", encoding="utf-8") as f:
        f.write(message + "\n")

# Clear previous log
with open(log_file_path, "w", encoding="utf-8") as f:
    f.write("=== COSWIN API DIAGNOSTIC V7 LOG ===\n")

log("Starting Coswin API diagnostics V7...")

# Test 1: Let's see what is returned for greater than 2026000000 (Year 2026)
log("\n--- TEST 1: greater than 2026000000 ---")
params = {**common_params, "filterOperator": "greater", "filterOperand1": "2026000000", "usePagination": "true"}
try:
    r = requests.get(base_url, params=params, auth=auth, timeout=15)
    log(f"Status: {r.status_code}")
    if r.status_code == 200:
        workorders = r.json().get("list", {}).get("workorderfind", [])
        log(f"Returned {len(workorders)} workorders.")
        if workorders:
            log(f"First workorder: code={workorders[0].get('wowoCode')}, date={workorders[0].get('wowoReportDate')}, entity={workorders[0].get('wowoRequestEntity')}")
            log(f"Last workorder: code={workorders[-1].get('wowoCode')}, date={workorders[-1].get('wowoReportDate')}, entity={workorders[-1].get('wowoRequestEntity')}")
            
            # Check if any DTAE is in the first page
            dtae_count = sum(1 for wo in workorders if str(wo.get("wowoRequestEntity")).upper() == "DTAE")
            log(f"DTAE workorders in page 1: {dtae_count}")
except Exception as e:
    log(f"Error in Test 1: {e}")

# Test 2: Let's see if we can find DTAE workorders by paging starting from 2026000000
log("\n--- TEST 2: Paging starting from 2026000000 ---")
params = {**common_params, "filterOperator": "greater", "filterOperand1": "2026000000", "usePagination": "true"}
pagination_context = None
pages_fetched = 0
matched_dtae = []
start_time = time.time()

while True:
    current_params = {**params}
    if pagination_context:
        current_params["paginationContext"] = pagination_context
        
    try:
        r = requests.get(base_url, params=current_params, auth=auth, timeout=10)
        if r.status_code != 200:
            log(f"  Error page {pages_fetched+1}: Status {r.status_code}")
            break
            
        data = r.json()
        workorders = data.get("list", {}).get("workorderfind", [])
        pages_fetched += 1
        
        # Look for DTAE
        for wo in workorders:
            entity = str(wo.get("wowoRequestEntity") or "").upper()
            if entity == "DTAE":
                matched_dtae.append(wo)
                
        more_data = bool(data.get("moreDataAvailable"))
        pagination_context = data.get("paginationContext")
        
        log(f"  Page {pages_fetched} loaded: {len(workorders)} items. DTAE matches: {len(matched_dtae)}")
        
        if not more_data or not pagination_context:
            log("  Reached end of pages.")
            break
            
        if pages_fetched >= 8: # Test up to 8 pages
            log("  Stopping at page 8 limit.")
            break
            
    except Exception as e:
        log(f"  Exception page {pages_fetched+1}: {e}")
        break

log(f"Paging summary: {pages_fetched} pages loaded in {time.time() - start_time:.2f} seconds. Found {len(matched_dtae)} DTAE workorders.")
if matched_dtae:
    for ot in matched_dtae[:5]:
        log(f"  - OT code={ot.get('wowoCode')}, status={ot.get('wowoUserStatus')}, date={ot.get('wowoReportDate')}")
else:
    log("  No DTAE workorders found in the pages loaded.")

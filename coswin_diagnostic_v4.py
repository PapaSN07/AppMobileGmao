import requests
from requests.auth import HTTPDigestAuth
from datetime import datetime, timedelta, timezone
import time
import json

base_url = "http://10.101.1.102:8083/ws/rest/workorders"
auth = HTTPDigestAuth("coswinws", "supervisor")
common_params = {
    "dataSource": "Coswin",
    "cwUser": "coswinws",
}

log_file_path = "coswin_api_diagnostic_v4.txt"

def log(message):
    print(message)
    with open(log_file_path, "a", encoding="utf-8") as f:
        f.write(message + "\n")

# Clear previous log
with open(log_file_path, "w", encoding="utf-8") as f:
    f.write("=== COSWIN API DIAGNOSTIC V4 LOG ===\n")

log("Starting Coswin API diagnostics V4...")

timeframes = [7, 15, 30, 45, 60, 90]

for days in timeframes:
    ref_date = (datetime.now(timezone.utc) - timedelta(days=days)).strftime("%Y-%m-%dT%H:%M:%SZ")
    log(f"\n--- TESTING TIMEFRAME: {days} days (referenceDate: {ref_date}) ---")
    
    start_time = time.time()
    pages_fetched = 0
    matched_dtae = []
    pagination_context = None
    
    while True:
        params = {
            **common_params,
            "filterOperator": "different",
            "filterOperand1": "0",
            "referenceDate": ref_date,
            "usePagination": "true",
        }
        if pagination_context:
            params["paginationContext"] = pagination_context
            
        try:
            r = requests.get(base_url, params=params, auth=auth, timeout=10)
            if r.status_code != 200:
                log(f"  Error on page {pages_fetched+1}: Status {r.status_code}")
                break
                
            data = r.json()
            workorders = data.get("list", {}).get("workorderfind", [])
            pages_fetched += 1
            
            # Search for DTAE in this page
            for wo in workorders:
                entity = str(wo.get("wowoRequestEntity") or "").upper()
                if entity == "DTAE":
                    matched_dtae.append({
                        "code": wo.get("wowoCode"),
                        "date": wo.get("wowoReportDate"),
                        "status": wo.get("wowoUserStatus"),
                        "equipment": wo.get("wowoEquipment")
                    })
            
            more_data = bool(data.get("moreDataAvailable"))
            pagination_context = data.get("paginationContext")
            
            # Print page info
            log(f"  Page {pages_fetched}: Loaded {len(workorders)} workorders. Cumulative DTAE found: {len(matched_dtae)}")
            
            if not more_data or not pagination_context:
                log("  Reached end of pages.")
                break
                
            # Limit page fetch to 10 pages per test to avoid taking too long
            if pages_fetched >= 10:
                log("  Reached limit of 10 pages.")
                break
                
        except Exception as e:
            log(f"  Exception on page {pages_fetched+1}: {e}")
            break
            
    elapsed = time.time() - start_time
    log(f"Timeframe {days} days summary:")
    log(f"  Pages loaded: {pages_fetched}")
    log(f"  DTAE workorders found: {len(matched_dtae)}")
    log(f"  Total execution time: {elapsed:.2f} seconds")
    if matched_dtae:
        log("  DTAE OTs:")
        for ot in matched_dtae[:5]:
            log(f"    - Code: {ot['code']}, Date: {ot['date']}, Status: {ot['status']}, Eq: {ot['equipment']}")

log("\nDiagnostics V4 complete. Output saved to coswin_api_diagnostic_v4.txt")

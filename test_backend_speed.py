import requests
from requests.auth import HTTPDigestAuth
import time
from datetime import datetime

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

print("Simulating backend call...")
start_time = time.time()

# 1. Calculate estimated max code
base_date = datetime(2026, 1, 1).date()
base_seq = 253020
daily_rate = 165
current_date = datetime.now().date()
days_diff = (current_date - base_date).days
estimated_seq = base_seq + int(days_diff * daily_rate)
estimated_max_code = (datetime.now().year * 1000000) + (estimated_seq % 1000000)

# We set starting_code to get only about 150 workorders (~1 day of work)
starting_code = estimated_max_code - 150
print(f"Estimated max code: {estimated_max_code}")
print(f"Starting code: {starting_code}")

params = {
    **common_params,
    "filterOperator": "greater",
    "filterOperand1": str(starting_code),
    "usePagination": "true"
}

matched_std = []
pagination_context = None
pages_fetched = 0
page_limit = 3 # Fetch max 3 pages (150 workorders)

while True:
    current_params = {**params}
    if pagination_context:
        current_params["paginationContext"] = pagination_context
        
    step_start = time.time()
    try:
        r = requests.get(base_url, params=current_params, auth=auth, proxies=direct_proxies, timeout=10)
        duration = time.time() - step_start
        pages_fetched += 1
        print(f"Page {pages_fetched} loaded in {duration:.2f}s with status {r.status_code}")
        
        if r.status_code == 200:
            data = r.json()
            workorders = data.get("list", {}).get("workorderfind", [])
            for wo in workorders:
                entity = str(wo.get("wowoRequestEntity") or "").upper()
                if entity == "STD":
                    matched_std.append(wo)
                    
            more_data = bool(data.get("moreDataAvailable"))
            pagination_context = data.get("paginationContext")
            
            if not more_data or not pagination_context:
                print("End of pages reached.")
                break
            if pages_fetched >= page_limit:
                print("Page limit reached.")
                break
        else:
            print(f"Non-200 response: {r.text[:200]}")
            break
    except Exception as e:
        print(f"Exception: {e}")
        break

total_duration = time.time() - start_time
print(f"\nCompleted in {total_duration:.2f}s.")
print(f"Matched {len(matched_std)} workorders for service STD:")
for wo in matched_std:
    print(f"  Code: {wo.get('wowoCode')} - Status: {wo.get('wowoUserStatus')} - Date: {wo.get('wowoReportDate')}")

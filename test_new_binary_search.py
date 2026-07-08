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

print("Starting Optimized Binary Search test...")
start_time = time.time()

current_year = datetime.now().year
low = current_year * 1000000 + 240000
high = current_year * 1000000 + 350000

print(f"Initial range: [{low}, {high}]")

max_code = low
iterations = 0

while low <= high and iterations < 20:
    iterations += 1
    mid = (low + high) // 2
    params = {
        **common_params,
        "filterOperator": "greater",
        "filterOperand1": str(mid),
        "usePagination": "true"
    }
    step_start = time.time()
    try:
        r = requests.get(base_url, params=params, auth=auth, proxies=direct_proxies, timeout=10)
        duration = time.time() - step_start
        print(f"Step {iterations}: mid={mid} -> Status {r.status_code} in {duration:.2f}s")
        if r.status_code == 200:
            workorders = r.json().get("list", {}).get("workorderfind", [])
            if workorders:
                max_code = mid
                low = mid + 1
            else:
                high = mid - 1
        else:
            print(f"  Non-200 response: {r.text[:200]}")
            high = mid - 1
    except Exception as e:
        duration = time.time() - step_start
        print(f"Step {iterations}: mid={mid} -> Error: {e} in {duration:.2f}s")
        high = mid - 1

# Fetch the last page to find the absolute max code
params = {
    **common_params,
    "filterOperator": "greater",
    "filterOperand1": str(max_code),
    "usePagination": "true"
}
try:
    r = requests.get(base_url, params=params, auth=auth, proxies=direct_proxies, timeout=10)
    if r.status_code == 200:
        workorders = r.json().get("list", {}).get("workorderfind", [])
        if workorders:
            absolute_max = max(int(wo.get("wowoCode", 0)) for wo in workorders)
            print(f"Found absolute max code: {absolute_max}")
            max_code = absolute_max
except Exception as e:
    print(f"Error fetching last page: {e}")

total_duration = time.time() - start_time
print(f"Binary search completed in {total_duration:.2f}s. Max code found: {max_code}")

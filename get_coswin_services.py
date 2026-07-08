import requests
from requests.auth import HTTPDigestAuth
import sys

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

print("Fetching active services from Coswin real database...")

entities = set()
entities_with_descriptions = {}

pagination_context = None
pages_to_fetch = 8  # Fetch up to 400 workorders to extract unique services

for page in range(pages_to_fetch):
    params = {
        **common_params,
        "filterOperator": "greater",
        "filterOperand1": "2026250000",
        "usePagination": "true"
    }
    if pagination_context:
        params["paginationContext"] = pagination_context
        
    try:
        r = requests.get(base_url, params=params, auth=auth, proxies=direct_proxies, timeout=15)
        if r.status_code == 200:
            data = r.json()
            workorders = data.get("list", {}).get("workorderfind", [])
            for wo in workorders:
                entity_code = wo.get("wowoRequestEntity")
                entity_desc = wo.get("wowoRequestEntityDescription")
                if entity_code:
                    entities.add(entity_code)
                    if entity_desc and entity_code not in entities_with_descriptions:
                        entities_with_descriptions[entity_code] = entity_desc
                        
            pagination_context = data.get("paginationContext")
            if not data.get("moreDataAvailable") or not pagination_context:
                break
        else:
            print(f"Error on page {page+1}: Status {r.status_code}")
            break
    except Exception as e:
        print(f"Exception on page {page+1}: {e}")
        break

print("\n=== ACTIVE SERVICE LIST (wowoRequestEntity) IN COSWIN ===")
if entities:
    for code in sorted(entities):
        desc = entities_with_descriptions.get(code, "Description not available")
        print(f"- {code} : {desc}")
else:
    print("No service codes found in the fetched workorders.")

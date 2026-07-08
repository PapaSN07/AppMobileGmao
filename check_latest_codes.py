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

print("Checking latest workorders starting from 2026250000...")
params = {
    **common_params,
    "filterOperator": "greater",
    "filterOperand1": "2026250000",
    "usePagination": "true"
}

try:
    r = requests.get(base_url, params=params, auth=auth, proxies=direct_proxies, timeout=15)
    if r.status_code == 200:
        data = r.json()
        workorders = data.get("list", {}).get("workorderfind", [])
        print(f"Total workorders in first page: {len(workorders)}")
        if workorders:
            print(f"First code in page: {workorders[0].get('wowoCode')} ({workorders[0].get('wowoReportDate')})")
            print(f"Last code in page: {workorders[-1].get('wowoCode')} ({workorders[-1].get('wowoReportDate')})")
            
            # Let's see if we can get the total count by paging to the end
            pagination_context = data.get("paginationContext")
            more = data.get("moreDataAvailable")
            page_count = 1
            total_count = len(workorders)
            
            while more and pagination_context and page_count < 15:
                params["paginationContext"] = pagination_context
                r2 = requests.get(base_url, params=params, auth=auth, proxies=direct_proxies, timeout=15)
                if r2.status_code == 200:
                    d2 = r2.json()
                    wos = d2.get("list", {}).get("workorderfind", [])
                    total_count += len(wos)
                    page_count += 1
                    pagination_context = d2.get("paginationContext")
                    more = d2.get("moreDataAvailable")
                    if wos:
                        print(f"Page {page_count}: Last code = {wos[-1].get('wowoCode')} ({wos[-1].get('wowoReportDate')})")
                else:
                    print(f"Error page {page_count+1}: {r2.status_code}")
                    break
            print(f"Total workorders counted in {page_count} pages: {total_count}")
    else:
        print(f"Error: {r.status_code}")
except Exception as e:
    print(f"Exception: {e}")

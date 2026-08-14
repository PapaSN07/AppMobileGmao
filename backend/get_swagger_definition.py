import urllib.request
import urllib.parse
import json
import re



urls_to_try = [
    "http://10.101.1.100:8083/ws/rest/api/swagger.json",
    "http://10.101.1.100:8083/ws/rest/api/swagger.yaml",
    "http://10.101.1.100:8083/ws/rest/api/openapi.json",
    "http://10.101.1.100:8083/ws/rest/api/api-docs",
    "http://10.101.1.100:8083/ws/rest/api-docs",
    "http://10.101.1.100:8083/ws/rest/swagger.json",
    "http://10.101.1.100:8083/ws/rest/api/index.html"
]

password_mgr = urllib.request.HTTPPasswordMgrWithDefaultRealm()
password_mgr.add_password(None, "http://10.101.1.100:8083", "admin", "admin")
handler = urllib.request.HTTPDigestAuthHandler(password_mgr)
# Disable system proxies explicitly by passing an empty ProxyHandler
no_proxy_handler = urllib.request.ProxyHandler({})
opener = urllib.request.build_opener(handler, no_proxy_handler)

print("Attempting to find API spec file from Senelec (Bypassing system proxy)...")

# Let's first read the HTML of index.html to see what JSON file it references
html_url = "http://10.101.1.100:8083/ws/rest/api/index.html"
try:
    req = urllib.request.Request(html_url)
    req.add_header("Accept", "text/html,application/xhtml+xml,application/xml")
    with opener.open(req, timeout=10) as response:
        html = response.read().decode('utf-8')
        print(f"Successfully loaded index.html ({len(html)} bytes)")
        
        # Look for url: "..." or url = "..." or similar references in JS
        urls = re.findall(r'url\s*:\s*["\']([^"\']+)["\']', html)
        print(f"URLs found in index.html: {urls}")
        for u in urls:
            # make it absolute
            abs_url = urllib.parse.urljoin(html_url, u)
            if abs_url not in urls_to_try:
                urls_to_try.insert(0, abs_url)
except Exception as e:
    print(f"Could not load index.html: {e}")

# Now let's try to fetch the spec files
for spec_url in urls_to_try:
    if "index.html" in spec_url:
        continue
    print(f"\nTrying to load spec from: {spec_url}")
    try:
        req = urllib.request.Request(spec_url)
        req.add_header("Accept", "application/json,text/yaml,*/*")
        with opener.open(req, timeout=10) as response:
            content = response.read()
            print(f"Success! Received {len(content)} bytes")
            # Let's try parsing it as JSON
            try:
                parsed = json.loads(content.decode('utf-8'))
                print("Successfully parsed as JSON!")
                
                # Print paths that match workorders
                paths = parsed.get("paths", {})
                wo_paths = [p for p in paths.keys() if "workorders" in p]
                print("\nWorkorders-related paths found in Swagger:")
                for p in wo_paths:
                    methods = list(paths[p].keys())
                    print(f"  - {p}: {methods}")
                break
            except Exception as json_err:
                # print a snippet if it's text/yaml
                print(f"Failed to parse as JSON: {json_err}")
                snippet = content.decode('utf-8', errors='ignore')[:300]
                print(f"Snippet:\n{snippet}")
    except Exception as e:
        print(f"Failed to load: {e}")

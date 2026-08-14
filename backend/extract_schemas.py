import urllib.request
import json

url = "http://10.101.1.100:8083/ws/rest/api/swagger.json"

password_mgr = urllib.request.HTTPPasswordMgrWithDefaultRealm()
password_mgr.add_password(None, "http://10.101.1.100:8083", "admin", "admin")
handler = urllib.request.HTTPDigestAuthHandler(password_mgr)
no_proxy_handler = urllib.request.ProxyHandler({})
opener = urllib.request.build_opener(handler, no_proxy_handler)

print("Fetching Swagger schemas from Senelec...")
try:
    req = urllib.request.Request(url)
    req.add_header("Accept", "application/json")
    with opener.open(req, timeout=10) as response:
        content = response.read()
        parsed = json.loads(content.decode('utf-8'))
        
        paths = parsed.get("paths", {})
        definitions = parsed.get("definitions", {})
        
        endpoints_to_check = ["/workorders", "/workorders/createSimple", "/workorders/createSimple0"]
        
        output_lines = []
        for ep in endpoints_to_check:
            path_data = paths.get(ep, {})
            post_data = path_data.get("post", {})
            if not post_data:
                output_lines.append(f"No POST method for {ep}")
                continue
                
            output_lines.append("="*50)
            output_lines.append(f"ENDPOINT: POST {ep}")
            output_lines.append(f"Summary: {post_data.get('summary', '')}")
            output_lines.append(f"Description: {post_data.get('description', '')}")
            
            parameters = post_data.get("parameters", [])
            output_lines.append("\nPARAMETERS:")
            for p in parameters:
                p_in = p.get("in")
                p_name = p.get("name")
                p_required = p.get("required", False)
                output_lines.append(f"  - {p_name} ({p_in}) - Required: {p_required}")
                
                # If schema parameter
                schema = p.get("schema", {})
                ref = schema.get("$ref")
                if ref:
                    def_name = ref.split("/")[-1]
                    output_lines.append(f"    Schema Ref: {def_name}")
                    
                    # Resolve ref
                    definition = definitions.get(def_name, {})
                    properties = definition.get("properties", {})
                    required_fields = definition.get("required", [])
                    output_lines.append(f"    Required properties: {required_fields}")
                    output_lines.append("    Properties details:")
                    for prop_name, prop_data in properties.items():
                        prop_type = prop_data.get("type", "object")
                        prop_format = prop_data.get("format", "")
                        prop_desc = prop_data.get("description", "")
                        output_lines.append(f"      * {prop_name} ({prop_type}{' - ' + prop_format if prop_format else ''}){' [REQUIRED]' if prop_name in required_fields else ''} - {prop_desc}")
                elif schema:
                    output_lines.append(f"    Inline Schema: {schema}")
            output_lines.append("\n")
            
        result_text = "\n".join(output_lines)
        print(result_text)
        
        # Save to file
        with open("schemas_output.txt", "w", encoding="utf-8") as f:
            f.write(result_text)
        print("Saved schemas to schemas_output.txt")
        
except Exception as e:
    print(f"Error fetching Swagger: {e}")

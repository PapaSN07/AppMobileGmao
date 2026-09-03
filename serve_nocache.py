import os
import sys
from http.server import SimpleHTTPRequestHandler, HTTPServer

class NoCacheHTTPRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

def run():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    web_dir = os.path.join(base_dir, 'frontend_mobile', 'build', 'web')
    if os.path.exists(web_dir):
        os.chdir(web_dir)
        print(f"Serving from: {web_dir}")
    else:
        print(f"Directory not found: {web_dir}")
        return

    server = HTTPServer(('0.0.0.0', 8080), NoCacheHTTPRequestHandler)
    print("Serving on http://0.0.0.0:8080 with NO-CACHE headers...")
    server.serve_forever()

if __name__ == '__main__':
    run()

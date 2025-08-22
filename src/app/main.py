import os
from http.server import BaseHTTPRequestHandler, HTTPServer


class Handler(BaseHTTPRequestHandler):
    def _send(self, code: int, body: bytes, content_type: str = "application/json") -> None:
        self.send_response(code)
        self.send_header("Content-Type", content_type)
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):  # noqa: N802 (method name from BaseHTTPRequestHandler)
        if self.path in ("/", "/health", "/healthz"):
            self._send(200, b'{"status":"ok"}')
        else:
            self._send(404, b'{"error":"not found"}')


def run() -> None:
    port = int(os.environ.get("APP_PORT", "8000"))
    addr = ("0.0.0.0", port)
    server = HTTPServer(addr, Handler)
    print(f"Serving on http://{addr[0]}:{addr[1]}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    run()


# apps/containerized-api/app/main.py
#
# Minimal HTTP API using Python's standard library.
#
# Endpoints:
#   GET /health  → 200 {"status": "healthy"}
#   GET /info    → 200 {"service": "...", "version": "...", ...}
#   GET /*       → 404 {"error": "not found"}
#
# Configuration via environment variables:
#   APP_PORT  - port to listen on (default: 8080)
#   APP_HOST  - host to bind to (default: 0.0.0.0)
#   APP_ENV   - environment name (default: production)

import json
import os
import platform
from http.server import HTTPServer, BaseHTTPRequestHandler


class APIHandler(BaseHTTPRequestHandler):
    """HTTP request handler for the containerized API."""

    def do_GET(self):
        """Handle GET requests."""
        path = self.path.rstrip("/")

        if path == "/health":
            self._send_json(200, {"status": "healthy"})
        elif path == "/info":
            self._send_json(200, self._info())
        else:
            self._send_json(404, {"error": "not found"})

    def _info(self):
        """Return service metadata."""
        return {
            "service": "containerized-api",
            "version": os.environ.get("APP_VERSION", "1.0.0"),
            "environment": os.environ.get("APP_ENV", "production"),
            "port": int(os.environ.get("APP_PORT", "8080")),
            "hostname": platform.node(),
            "python_version": platform.python_version(),
        }

    def _send_json(self, status_code, data):
        """Send a JSON response."""
        response = json.dumps(data, indent=2).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(response)))
        self.end_headers()
        self.wfile.write(response)

    def log_message(self, format, *args):
        """Override to suppress default logging to stderr."""
        pass


def main():
    """Start the HTTP server."""
    host = os.environ.get("APP_HOST", "0.0.0.0")
    port = int(os.environ.get("APP_PORT", "8080"))

    server = HTTPServer((host, port), APIHandler)
    print(f"Starting containerized-api on {host}:{port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down...")
        server.shutdown()


if __name__ == "__main__":
    main()

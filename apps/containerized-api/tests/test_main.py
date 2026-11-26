# apps/containerized-api/tests/test_main.py
#
# Unit tests for the containerized API.
#
# Tests verify the HTTP handler responds correctly to known endpoints
# and returns 404 for unknown paths.

import json
import unittest
from unittest.mock import Mock
from io import BytesIO

from app.main import APIHandler


class TestAPIHandler(unittest.TestCase):
    """Tests for the API HTTP handler response logic."""

    def setUp(self):
        """Set up a mock handler for each test."""
        # Create a handler with a real server mock
        server_mock = Mock()
        server_mock.server_address = ("0.0.0.0", 8080)

        # Create the handler
        self.handler = APIHandler.__new__(APIHandler)
        self.handler.server = server_mock
        self.handler.client_address = ("127.0.0.1", 12345)
        self.handler.request = Mock()
        self.handler.requestline = "GET /health HTTP/1.1"
        self.handler.raw_requestline = b"GET /health HTTP/1.1"
        self.handler.command = "GET"
        self.handler.path = "/health"
        self.handler.request_version = "HTTP/1.1"
        self.handler.headers = Mock()

        # Capture output
        self.handler.wfile = BytesIO()
        self.handler.send_response = Mock()
        self.handler.send_header = Mock()
        self.handler.end_headers = Mock()

    def _get_response(self):
        """Get the captured response body as a dict."""
        body = self.handler.wfile.getvalue()
        # The response is JSON after the headers
        # Find the JSON part (after the blank line)
        parts = body.split(b"\r\n\r\n", 1)
        if len(parts) > 1:
            return json.loads(parts[1].decode("utf-8"))
        return json.loads(body.decode("utf-8"))

    def test_health_endpoint(self):
        """GET /health returns 200 with status healthy."""
        self.handler.path = "/health"
        self.handler.do_GET()

        data = self._get_response()
        self.assertEqual(data["status"], "healthy")

    def test_health_endpoint_trailing_slash(self):
        """GET /health/ returns 200 with status healthy."""
        self.handler.path = "/health/"
        self.handler.do_GET()

        data = self._get_response()
        self.assertEqual(data["status"], "healthy")

    def test_info_endpoint(self):
        """GET /info returns service metadata."""
        self.handler.path = "/info"
        self.handler.do_GET()

        data = self._get_response()
        self.assertEqual(data["service"], "containerized-api")
        self.assertIn("version", data)
        self.assertIn("environment", data)
        self.assertIn("port", data)

    def test_info_endpoint_trailing_slash(self):
        """GET /info/ returns service metadata."""
        self.handler.path = "/info/"
        self.handler.do_GET()

        data = self._get_response()
        self.assertEqual(data["service"], "containerized-api")

    def test_unknown_endpoint_returns_404(self):
        """GET /unknown returns 404 with error message."""
        self.handler.path = "/unknown"
        self.handler.do_GET()

        data = self._get_response()
        self.assertEqual(data["error"], "not found")

    def test_root_endpoint_returns_404(self):
        """GET / (empty path) returns 404."""
        self.handler.path = "/"
        self.handler.do_GET()

        data = self._get_response()
        self.assertEqual(data["error"], "not found")

    def test_nested_unknown_endpoint_returns_404(self):
        """GET /api/v1/nonexistent returns 404."""
        self.handler.path = "/api/v1/nonexistent"
        self.handler.do_GET()

        data = self._get_response()
        self.assertEqual(data["error"], "not found")

    def test_health_response_structure(self):
        """Health endpoint response has expected structure."""
        self.handler.path = "/health"
        self.handler.do_GET()

        data = self._get_response()
        self.assertIn("status", data)
        self.assertEqual(len(data), 1)  # Only "status" key

    def test_info_response_structure(self):
        """Info endpoint response has expected structure."""
        self.handler.path = "/info"
        self.handler.do_GET()

        data = self._get_response()
        expected_keys = {"service", "version", "environment", "port", "hostname", "python_version"}
        self.assertEqual(set(data.keys()), expected_keys)
        self.assertEqual(data["service"], "containerized-api")


if __name__ == "__main__":
    unittest.main()

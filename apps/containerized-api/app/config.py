# apps/containerized-api/app/config.py
#
# Application configuration loaded from environment variables.
#
# This module centralizes configuration so the main module can import
# settings rather than reading os.environ in multiple places.

import os


class Config:
    """Application configuration from environment variables."""

    host: str = os.environ.get("APP_HOST", "0.0.0.0")
    port: int = int(os.environ.get("APP_PORT", "8080"))
    environment: str = os.environ.get("APP_ENV", "production")
    version: str = os.environ.get("APP_VERSION", "1.0.0")


# Module-level convenience instance
config = Config()

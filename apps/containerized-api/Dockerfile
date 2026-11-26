# apps/containerized-api/Dockerfile
#
# Multi-stage build for the containerized API.
#
# Stage 1 (builder): Copy application code and verify syntax.
# Stage 2 (runtime): Minimal image with non-root user and health check.
#
# Base image: python:3.11-slim (Debian-based, minimal, ~120MB)
#
# Security:
#   - Non-root user (appuser, UID 1000)
#   - Minimal base image
#   - No unnecessary packages
#   - HEALTHCHECK instruction for container monitoring
#
# Build:
#   docker build -t containerized-api:latest .
#
# Run:
#   docker run -d --name api -p 8080:8080 containerized-api:latest

# -----------------------------------------------------------------------------
# Stage 1: Builder
# -----------------------------------------------------------------------------
# Copies the application code and verifies it compiles without errors.
# This stage can be extended later to run tests or linting.

FROM python:3.11-slim AS builder

WORKDIR /build

# Copy application code
COPY app/ ./app/

# Verify Python syntax compiles without errors
# This catches syntax errors before the runtime stage
RUN python3 -m py_compile app/main.py && \
    python3 -m py_compile app/config.py && \
    echo "Build stage: syntax verification passed"

# -----------------------------------------------------------------------------
# Stage 2: Runtime
# -----------------------------------------------------------------------------
# Minimal image with the application, non-root user, and health check.

FROM python:3.11-slim

# ---------------------------------------------------------------------------
# Build metadata labels
# ---------------------------------------------------------------------------
# These labels follow the OpenContainers image spec and are used by
# container registries, image scanners, and orchestration tools.

LABEL org.opencontainers.image.title="containerized-api"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.description="Minimal Python HTTP API with health endpoint"
LABEL org.opencontainers.image.authors="Infrastructure Lab"
LABEL org.opencontainers.image.source="https://github.com/org/terraform-aws-modular"
LABEL org.opencontainers.image.licenses="MIT"

# ---------------------------------------------------------------------------
# Create non-root user
# ---------------------------------------------------------------------------
# The container process runs as UID 1000 (appuser), not root.
# This limits the impact of a container breakout or application vulnerability.

RUN useradd --create-home --shell /bin/bash --uid 1000 appuser

# ---------------------------------------------------------------------------
# Set working directory
# ---------------------------------------------------------------------------

WORKDIR /app

# ---------------------------------------------------------------------------
# Copy application from builder stage
# ---------------------------------------------------------------------------
# Only the compiled application code is copied. Build artifacts, tests, and
# development files are left in the builder stage.

COPY --from=builder /build/app/ ./app/

# ---------------------------------------------------------------------------
# Set ownership
# ---------------------------------------------------------------------------
# The appuser owns the application directory.

RUN chown -R appuser:appuser /app

# ---------------------------------------------------------------------------
# Switch to non-root user
# ---------------------------------------------------------------------------
# All subsequent RUN, CMD, and ENTRYPOINT instructions run as appuser.

USER appuser

# ---------------------------------------------------------------------------
# Expose port
# ---------------------------------------------------------------------------
# Documents that the container listens on port 8080. This is informational
# — it does not actually publish the port. Use -p or --publish to expose.

EXPOSE 8080

# ---------------------------------------------------------------------------
# Health check
# ---------------------------------------------------------------------------
# Docker periodically runs this command to check if the container is healthy.
# If the health check fails 3 times in a row, the container is marked unhealthy.
#
#   --interval=30s   : check every 30 seconds
#   --timeout=5s     : kill the check if it takes more than 5 seconds
#   --start-period=5s : grace period for container startup
#   --retries=3      : mark unhealthy after 3 consecutive failures
#
# This health check is used by:
#   - Docker Compose (docker compose up --health-cmd ...)
#   - ECS task definitions
#   - Kubernetes liveness/readiness probes

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')" || exit 1

# ---------------------------------------------------------------------------
# Default command
# ---------------------------------------------------------------------------
# Starts the Python HTTP server. The -m flag runs the app.main module
# as a script. No shell wrapper is needed.

CMD ["python3", "-m", "app.main"]

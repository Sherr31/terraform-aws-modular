# apps/containerized-api/README.md

# Containerized API

A minimal Python HTTP API with a health endpoint, designed for container deployment on AWS.

## Application

A simple HTTP server built with Python's standard library. No external dependencies.

### Endpoints

| Endpoint | Method | Response | Description |
|----------|--------|----------|-------------|
| `/health` | GET | `{"status": "healthy"}` | Health check for containers and load balancers |
| `/info` | GET | `{"service": "...", "version": "...", ...}` | Service metadata |
| `/*` | GET | `{"error": "not found"}` | 404 for undefined routes |

### Running locally (without Docker)

```bash
cd apps/containerized-api

python3 -m app.main
```

Then open `http://localhost:8080/health` in a browser or use curl:

```bash
curl http://localhost:8080/health
curl http://localhost:8080/info
```

### Running with Docker

```bash
cd apps/containerized-api

# Build the image
docker build -t containerized-api:latest .

# Run the container
docker run -d --name api -p 8080:8080 containerized-api:latest

# Check health
curl http://localhost:8080/health

# View logs
docker logs api

# Stop and remove
docker stop api
docker rm api
```

### Running with Docker Compose

```bash
cd apps/containerized-api

# Start the service
docker compose up -d

# Check health
curl http://localhost:8080/health

# View logs
docker compose logs -f

# Stop and remove
docker compose down
```

**Note:** Docker Compose requires port 8080 to be available on the host. If port 8080 is already in use, either stop the conflicting service or modify `compose.yaml` to use a different host port (e.g., `"8081:8080"`).

To use a different host port, edit `compose.yaml`:

```yaml
ports:
  - "8081:8080"  # Host port 8081 → container port 8080
```

Then access the API at `http://localhost:8081` instead.

## Configuration

The application is configured via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `APP_PORT` | `8080` | Port the server listens on |
| `APP_HOST` | `0.0.0.0` | Host to bind to |
| `APP_ENV` | `production` | Environment name (shown in /info) |

Example with custom port:

```bash
APP_PORT=3000 docker run -p 3000:3000 containerized-api:latest
```

## Health check

The `/health` endpoint returns HTTP 200 with:

```json
{
  "status": "healthy"
}
```

This is the endpoint used by:
- Docker `HEALTHCHECK` instruction
- ALB target group health checks
- Kubernetes liveness/readiness probes

## Dockerfile

The Dockerfile uses a multi-stage build:

1. **Build stage** — copies the application and verifies syntax
2. **Runtime stage** — creates a minimal image with a non-root user

```dockerfile
# Build stage
FROM python:3.11-slim AS builder
WORKDIR /build
COPY app/ ./app/
RUN python3 -m py_compile app/main.py

# Runtime stage
FROM python:3.11-slim
RUN useradd --create-home --shell /bin/bash appuser
WORKDIR /app
COPY --from=builder /build/app/ ./app/
USER appuser
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')"
CMD ["python3", "-m", "app.main"]
```

### Why these choices

| Choice | Reason |
|--------|--------|
| `python:3.11-slim` | Minimal Debian-based image with Python. Smaller than full Debian, more compatible than Alpine (Alpine has musl libc issues with some Python packages). |
| Non-root user | Security best practice. The container process runs as UID 1000, not root. |
| Multi-stage | Even without compilation, keeps build artifacts out of the final image. Extensible for future testing stages. |
| `HEALTHCHECK` | Docker can monitor container health automatically. Used by ECS, Compose, and Kubernetes. |
| `EXPOSE 8080` | Documents the port. Not required for functionality but helpful for tooling. |
| `CMD ["python3", "-m", "app.main"]` | Runs the module directly. No shell wrapper needed. |

## Docker Compose

`compose.yaml` defines the local development environment:

```yaml
services:
  api:
    build: .
    ports:
      - "8080:8080"
    environment:
      - APP_PORT=8080
      - APP_ENV=development
    healthcheck:
      test: ["CMD", "python3", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 5s
```

### Compose commands

```bash
# Start
docker compose up -d

# View logs
docker compose logs -f api

# Restart
docker compose restart api

# Rebuild and restart
docker compose up -d --build

# Stop and remove
docker compose down

# Stop, remove, and delete volumes
docker compose down -v
```

## Testing

### Manual testing

```bash
# Health endpoint
curl http://localhost:8080/health

# Info endpoint
curl http://localhost:8080/info

# Unknown endpoint (expect 404)
curl http://localhost:8080/nonexistent

# Headers
curl -I http://localhost:8080/health
```

Expected responses:

```bash
$ curl http://localhost:8080/health
{"status": "healthy"}

$ curl http://localhost:8080/info
{"service": "containerized-api", "version": "1.0.0", "environment": "development", "port": 8080}

$ curl http://localhost:8080/nonexistent
{"error": "not found"}
```

### Automated tests

Tests must be run from the `apps/containerized-api/` directory so Python can find the `app` package:

```bash
cd apps/containerized-api

# Run with unittest (stdlib, no dependencies)
python3 -m unittest discover -v

# Run with pytest (if installed)
python3 -m pytest tests/ -v
```

All 9 tests should pass:

- `test_health_endpoint` — GET /health returns 200 with `{"status": "healthy"}`
- `test_health_endpoint_trailing_slash` — GET /health/ also works
- `test_health_response_structure` — health response has only the `status` key
- `test_info_endpoint` — GET /info returns service metadata
- `test_info_endpoint_trailing_slash` — GET /info/ also works
- `test_info_response_structure` — info response has all expected keys
- `test_unknown_endpoint_returns_404` — unknown paths return 404
- `test_root_endpoint_returns_404` — GET / returns 404
- `test_nested_unknown_endpoint_returns_404` — nested unknown paths return 404

## Security considerations

- **Non-root user:** The container runs as UID 1000, not root. This limits the impact of a container breakout.
- **Minimal base image:** `python:3.11-slim` is smaller than the full image and has fewer packages to audit.
- **No secrets in the image:** Configuration is via environment variables, not baked into the image.
- **Read-only filesystem ready:** The application doesn't write to disk. For production, add `--read-only` to Docker run or `read_only: true` in Compose.
- **No unnecessary packages:** The image contains only Python and the application code. No compilers, no shell utilities beyond what the base image provides.

## Image size

The final image is approximately 120-150 MB (Python 3.11 slim + application code). This is small enough for quick pulls and deployments.

## Deployment to AWS

The containerized API is deployed to AWS through two GitHub Actions workflows:

| Workflow | Trigger | What it does |
|----------|---------|-------------|
| `docker-ci.yml` | PRs/pushes to `apps/containerized-api/**` | Builds, tests, and scans the image |
| `docker-publish.yml` | After Docker CI succeeds on `main` | Pushes the tested image to Amazon ECR |
| `app-deploy.yml` | Manual or after publish on `main` | Deploys to an EC2 host via SSH |

### Pipeline overview

```
Code change
  → Docker CI (build + test + Trivy scan)
    → Docker Publish (push to ECR, only if CI passed)
      → Application Deploy (pull to EC2, verify, rollback on failure)
```

### Image tags

| Tag | Purpose |
|-----|---------|
| `sha-<commit>` | Immutable, canonical, used by deployments |
| `latest` | Convenience, updated on every publish |

Deployments pin to `sha-<commit>`. The `latest` tag is for convenience only.

### Deployment model

The GitHub Actions runner bridges the gap to ECR. The deploy target EC2 host has **no AWS credentials and no ECR access**:

1. Runner authenticates to ECR via OIDC
2. Runner pulls the image from ECR
3. Runner saves the image as a tarball and `scp`s it to the host
4. Host loads the tarball, writes `.env`, runs `docker compose up -d`
5. Host is verified (health + endpoints)

### Rollback

If verification fails, the deploy script restores the previous image (backed up before the deploy) and re-verifies. Rollback does not require ECR access from the host.

### Required configuration

For the deployment to work, configure these as GitHub Secrets:

| Secret | Purpose |
|--------|---------|
| `EC2_HOST` | Deploy target hostname or IP |
| `EC2_USER` | SSH user (default `ec2-user`) |
| `EC2_SSH_PRIVATE_KEY` | SSH private key with access to the host |
| `ECR_REPO_URI` | Full ECR repository URI |
| `AWS_ROLE_ARN` | OIDC role with ECR access |
| `AWS_REGION` | (optional) default `us-east-1` |

The deploy target must have Docker Engine and the Docker Compose v2 plugin installed.

### Security

- The SSH private key is written to a 600 file and never printed to logs.
- ECR credentials are short-lived (OIDC), scoped to the minimum permission.
- The deploy target has no AWS credentials of its own.

### Local testing of the deployment flow

You can test the deployment mechanics locally without AWS by simulating the "remote host" as a directory:

```bash
cd apps/containerized-api

# Build the image with an ECR-like tag
docker build -t 123456789012.dkr.ecr.us-east-1.amazonaws.com/containerized-api:sha-test .

# Simulate the remote host directory
REMOTE=/tmp/deploy-host-sim
rm -rf "$REMOTE"
mkdir -p "$REMOTE/opt/containerized-api"

# Save the image as a tarball (what the runner does)
docker save 123456789012.dkr.ecr.us-east-1.amazonaws.com/containerized-api:sha-test -o /tmp/api.tar

# Transfer to the "remote" (what scp does)
cp compose.prod.yaml "$REMOTE/opt/containerized-api/"
cp /tmp/api.tar "$REMOTE/opt/containerized-api/"

# Deploy on the "remote" (load + compose up)
cd "$REMOTE/opt/containerized-api"
cat > .env <<ENV
ECR_REPO_URI=123456789012.dkr.ecr.us-east-1.amazonaws.com/containerized-api
IMAGE_TAG=sha-test
HOST_PORT=8083
ENV
docker load -i api.tar
docker compose -f compose.prod.yaml up -d

# Verify
curl http://localhost:8083/health
curl http://localhost:8083/info
curl -s -o /dev/null -w '%{http_code}' http://localhost:8083/nonexistent

# Cleanup
docker compose -f compose.prod.yaml down -v
cd /terraform-aws-modular
rm -rf "$REMOTE" /tmp/api.tar
docker rmi 123456789012.dkr.ecr.us-east-1.amazonaws.com/containerized-api:sha-test
```

This exercises the same commands the `app-deploy.yml` workflow runs on the EC2 host.

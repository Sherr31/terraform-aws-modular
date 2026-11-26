# CI/CD Workflows

This directory contains GitHub Actions workflows for the `terraform-aws-modular` project.

## Workflows

### PR Validation (`pr-validation.yml`)

Runs on every pull request to `main`. Includes:

- **Terraform Format Check** — `terraform fmt -check -recursive` across the project
- **Terraform Validate** — `terraform init -backend=false` + `terraform validate` in each root configuration
- **Security Scan** — Checkov scan for Terraform security best practices

### Push Validation (`push-validation.yml`)

Runs on every push to `main`. Same format and validate checks as PR validation, but without the security scan. Confirms `main` stays valid after merges.

### Docker CI (`docker-ci.yml`)

Runs on pull requests and pushes affecting `apps/containerized-api/**` or the workflow file itself.

| Job | Purpose |
|-----|---------|
| `unit-tests` | Runs the 9 application unit tests with `python3 -m unittest discover` from the app directory |
| `build` | Builds the image with Buildx, caches layers in GitHub Actions cache, exports the image as an artifact |
| `compose-test` | Loads the image, runs `docker compose up -d`, polls container health for up to 60s, verifies `/health`, `/info`, and 404 handling |
| `trivy-scan` | Scans the image for vulnerabilities and uploads SARIF to code scanning |

**This workflow never deploys and never publishes.** Publishing is `docker-publish.yml` (Phase 9, main branch only).

#### Trivy severity policy

| Severity | Behavior | Why |
|----------|----------|-----|
| CRITICAL (fixable) | **Blocks the build** (`exit-code: 1`) | Critical, exploitable, with a known fix — must be resolved |
| HIGH (fixable) | Reported in SARIF + job summary (`exit-code: 0`) | Base images routinely carry HIGH findings in OS packages the application cannot control; blocking on these trains people to ignore red builds |
| Unfixed | Not reported (`ignore-unfixed: true`) | Nothing can be done until upstream ships a fix |

Verified locally against `python:3.11-slim`: 0 CRITICAL, 3 HIGH. The blocking step therefore passes on the current base image, while HIGH findings stay visible in code scanning.

#### Change isolation

Path filters mean Terraform-only changes do not trigger Docker CI, and application changes do not trigger Terraform CI. Editing `docker-ci.yml` itself does trigger it.

### Docker Publish (`docker-publish.yml`)

Runs only when Docker CI completes successfully on `main` (via `workflow_run`) or when manually dispatched. It publishes tested images to Amazon ECR.

| Trigger | Behavior |
|---------|----------|
| `workflow_run` on Docker CI success (main) | Publishes the image from that CI run, using the CI run's commit SHA |
| `workflow_dispatch` | Manual publish; optionally supply a specific commit SHA to publish |

| Step | Purpose |
|------|--------|
| Resolve commit SHA | Uses the triggering CI run's SHA, or a supplied SHA, or finds the latest successful Docker CI run on main via the API |
| Configure AWS credentials | OIDC → AWS role with ECR push permissions |
| Login to ECR | `aws ecr get-login-password` → `docker login` |
| Download tested image | Downloads the image tarball artifact that Docker CI produced (same bytes that were tested) |
| Load image | `docker load` from the artifact |
| Trivy scan (CRITICAL) | Final gate before publish; blocks on CRITICAL fixable findings |
| Trivy scan (SARIF) | Records HIGH + CRITICAL findings in code scanning |
| Tag | `sha-<commit>` (immutable, canonical) and `latest` (convenience) |
| Push | `docker push` both tags |
| Summary | Lists pushed URIs and the commit SHA |

**Only successfully tested images are published.** Because publish runs only after Docker CI succeeds on the same commit, and it pushes the exact artifact Docker CI built (not a rebuild), the published image is identical to the one that passed all tests.

**Immutable tags.** The `sha-<commit>` tag is the deployment source of truth. The `latest` tag is for convenience only. Pin deployments to the SHA tag.

#### Required secrets

| Secret | Purpose |
|--------|---------|
| `AWS_ROLE_ARN` | OIDC role with ECR push permissions (`ecr:BatchCheckLayerAvailability`, `ecr:CompleteLayerUpload`, `ecr:InitiateLayerUpload`, `ecr:UploadLayerPart`, `ecr:PutImage`, `ecr:GetAuthorizationToken`) |
| `ECR_REPO_URI` | Full ECR repository URI, e.g. `123456789012.dkr.ecr.us-east-1.amazonaws.com/containerized-api` |
| `AWS_REGION` | (optional) AWS region, default `us-east-1` |

#### Recording the published version

The workflow writes the pushed image URIs and the commit SHA to the job summary. The immutable `sha-<commit>` tag is also the reference used by `app-deploy.yml`, so the published version is traceable end-to-end.

### Application Deploy (`app-deploy.yml`)

Deploys the containerized API to an EC2 host via SSH. Triggers:

| Trigger | Behavior |
|---------|----------|
| `workflow_dispatch` (manual) | Select the image tag and optionally the target host/port |
| `workflow_run` on Docker Publish success (main) | Queues a deployment of the just-published `sha-<commit>` image |

Both require approval through the GitHub Environment `production` (configure required reviewers). If the environment is not configured, approval is skipped — configure it for production use.

| Step | Purpose |
|------|--------|
| Resolve image tag | Uses the input tag, or `latest`, or the commit SHA from the triggering publish run |
| Configure AWS credentials | OIDC → AWS role with ECR read (`GetAuthorizationToken`) |
| Login to ECR | `aws ecr get-login-password` → `docker login` (runner only; the host has no AWS access) |
| Validate configuration | Confirms `EC2_HOST` and `ECR_REPO_URI` are set |
| Prepare SSH key | Writes the SSH private key to a 600 file; never printed to logs |
| Scan host key | `ssh-keyscan` at deploy time (pin for production) |
| Transfer image to host | Runner pulls from ECR, saves to tarball, `scp` to the host |
| Deploy (SSH) | Host loads the tarball, writes `.env`, `docker compose up -d`, verifies health + endpoints |
| Rollback | On verification failure, restores the previous image from a cached tarball and re-verifies |
| Summary | Records deployed image, host, port, and method |

#### Deployment model

The GitHub runner is the bridge to ECR. It pulls the image (it has credentials), saves it as a tarball, and transfers it to the host via `scp`. The host then:

1. Backs up the previous image (if cached) to a tarball
2. Loads the new image from the transferred tarball
3. Writes `.env` with `ECR_REPO_URI`, `IMAGE_TAG`, `HOST_PORT`
4. Runs `docker compose -f compose.prod.yaml up -d`
5. Polls container health, then verifies `/health`, `/info`, and 404 handling

#### Rollback

Before deploying, if the previous image tag is cached locally on the host, the deploy script saves it as `.prev_image.tar`. On verification failure, it restores `.env` to the previous tag, loads the backed-up tarball, and runs `docker compose up -d` again. This makes rollback independent of ECR access from the host.

#### Required secrets

| Secret | Purpose |
|--------|---------|
| `EC2_HOST` | Deploy target hostname or IP |
| `EC2_USER` | SSH user (default `ec2-user`) |
| `EC2_SSH_PRIVATE_KEY` | SSH private key with access to the host |
| `ECR_REPO_URI` | Full ECR repository URI |
| `AWS_ROLE_ARN` | OIDC role with ECR read (`GetAuthorizationToken`) |
| `AWS_REGION` | (optional) default `us-east-1` |

#### Deploy target prerequisites

The EC2 host must have Docker Engine and the Docker Compose v2 plugin (`docker compose`) installed, and be reachable from GitHub Actions runners (directly or via a bastion).

#### Security notes

- The SSH private key is written to a 600 file and never printed to logs.
- The SSH host key is scanned at deploy time; pin it for production.
- ECR credentials are short-lived (OIDC) and scoped to `GetAuthorizationToken`.
- The image tag, host, and repo URI passed on the SSH command line are not secrets; they may appear in runner logs.

## Security Scan Notes

## Security Scan Notes

The Checkov scan uses `soft_fail: true`, which means security findings are reported but do not block the PR. This is intentional for a learning project where some warnings may be acceptable.

To make the security scan blocking, change `soft_fail: true` to `soft_fail: false`.

### Skipped Checks

Some Checkov checks are skipped because they are too strict for a module library or produce false positives in example configurations:

- `CKV_AWS_20` — S3 bucket versioning (examples show S3 with versioning configurable; not every example enables it)
- `CKV_AWS_24` — S3 public access block (examples focus on module usage; some may not set this explicitly)
- `CKV_AWS_33` — S3 encryption (encryption is often handled by the module, not the example)
- `CKV_AWS_117` — EBS encryption (module default may handle this; examples pass through)
- `CKV_AWS_119` — RDS encryption (not applicable — RDS is out of scope)
- `CKV_AWS_144` — KMS key rotation (examples typically use default service keys)
- `CKV_AWS_227` — SSM parameter encryption (not applicable to current examples)
- `CKV_AWS_301` through `CKV_AWS_315` — Security group and network checks that flag open ingress/egress rules commonly used in examples for learning purposes

**Note:** The scan runs only against `examples/` and `bootstrap/` (not `modules/`) to reduce false positives from reusable module patterns.

Start with this minimal skip list. If Checkov flags a real issue, fix the code. If it flags a false positive, add the check to the skip list with a comment explaining why. Remove skips when they are no longer needed.

## Terraform Version

Both workflows use Terraform 1.17.1, matching the version documented in module `versions.tf` files (`>= 1.5.0`). Update the version in both workflows if the project upgrades.

## Adding New Examples

When adding a new example or bootstrap configuration:

1. Add the directory to the `matrix.directory` list in both workflow files
2. Ensure the example validates with `terraform init -backend=false` and `terraform validate`

## Local Testing

You can test the validation locally before pushing:

```bash
# Format check
terraform fmt -check -recursive

# Validate each configuration
for dir in examples/*/ bootstrap/terraform-state/; do
  pushd "$dir" > /dev/null
  terraform init -backend=false > /dev/null 2>&1
  terraform validate
  popd > /dev/null
done
```

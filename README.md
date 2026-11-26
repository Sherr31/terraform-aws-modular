# terraform-aws-modular

A collection of reusable Terraform modules for AWS infrastructure, with integrated applications, CI/CD pipelines, and local helper scripts.

terraform-aws-modular/
├── modules/          # Reusable child modules (no state, no provider config)
│   ├── vpc/          # VPC with public/private subnets, IGW, optional NAT
│   ├── ec2/          # Single EC2 instance with secure defaults
│   ├── s3/           # S3 bucket with encryption, versioning, lifecycle
│   ├── iam/          # IAM role, policy, and instance profile
│   ├── security-group/ # Security group with ingress/egress rules
│   ├── alb/          # Application Load Balancer with target group
│   ├── autoscaling/  # Auto Scaling group with launch template
│   └── ecr/          # ECR repository with scanning and lifecycle
├── examples/         # Standalone root configurations demonstrating module usage
│   ├── vpc/          # Example: deploy the VPC module
│   ├── ec2/          # Example: deploy an EC2 instance
│   ├── s3/           # Example: deploy an S3 bucket
│   ├── iam/          # Example: deploy an IAM role
│   ├── security-group/ # Example: deploy a security group
│   ├── alb/          # Example: deploy an ALB
│   ├── autoscaling/  # Example: deploy an ASG
│   └── ecr/          # Example: deploy an ECR repository
├── bootstrap/        # Bootstrap configurations for project infrastructure
│   └── terraform-state/ # S3 bucket + DynamoDB for remote state
├── apps/             # Integrated application configurations
│   ├── infrastructure-lab/ # Complete app: VPC + SG + EC2 + ALB + ASG
│   └── containerized-api/  # Minimal Python HTTP API in a container
├── scripts/          # Local helper scripts (validate, fmt, plan, security scan)
├── .github/workflows/ # CI/CD pipelines
└── .gitignore        # Excludes state, .terraform/, secrets, and module artifacts
```

## Getting Started

This section covers how to run and test the project locally. It is a top-to-bottom path: install dependencies, check formatting, validate the Terraform, and run the containerized API.

### Prerequisites

| Tool | Minimum version | Used for |
|------|-----------------|----------|
| Terraform | 1.5.0 | All `terraform` commands |
| Docker | 24+ | Building and running the containerized API |
| Docker Compose v2 | 2.x | `docker compose` commands |
| Python | 3.11 | Running the API locally and its tests |
| Git | any | Cloning the repository |

### Install

```bash
# Clone
cd terraform-aws-modular

# (Optional) Use a Terraform version manager
# tfenv install 1.17.1 && tfenv use 1.17.1

# For Checkov scans (optional, used by scripts/checkov-scan.sh)
pip install checkov

# For the secret scan (optional, used by scripts/pr-check.sh)
pip install gitleaks
```

### Terraform: check formatting

```bash
terraform fmt -check -recursive
```

To auto-fix (local only, do not commit un-reviewed reformatting):

```bash
./scripts/fmt-check.sh --fix
```

### Terraform: validate all configurations

```bash
./scripts/validate-all.sh
```

This runs `terraform init -backend=false` + `terraform validate` for every root config (examples, bootstrap, infrastructure-lab). It does not require AWS credentials or the state bucket.

### Terraform: plan (no apply)

```bash
./scripts/plan-all.sh
```

Plans are written to `plans/` as both binary `.plan` and human-readable `.txt`. To inspect one:

```bash
terraform show plans/vpc.plan
```

These plans use `-backend=false`, so they are local-only previews. For the real plan against remote state, run `terraform plan` in the individual directory after the bootstrap is deployed and the backend is configured.

### Terraform: deploy an example (local state)

To try an example with local state (no bootstrap needed yet):

```bash
cd examples/vpc
terraform init
terraform plan
terraform apply

# When finished
terraform destroy
```

Each example has its own state file, so destroying one does not affect the others.

### Terraform: remote state (after bootstrap)

Once the bootstrap S3 bucket and DynamoDB table exist:

1. Edit each `backend.tf`, replacing `BUCKET_NAME` and `LOCK_TABLE_NAME` with the real names from the bootstrap output.
2. Run `terraform init` in the example — Terraform will offer to migrate the local state to the remote bucket.
3. Use the Terraform CD workflow (`terraform-deploy.yml`) or run `terraform apply` manually.

See the [Backend State](README.md#backend-state) section and `bootstrap/terraform-state/README.md`.

### Containerized API: run locally (no Docker)

```bash
cd apps/containerized-api
python3 -m app.main
```

Then:

```bash
curl http://localhost:8080/health
curl http://localhost:8080/info
curl http://localhost:8080/nonexistent   # expect 404
```

### Containerized API: run with Docker

```bash
cd apps/containerized-api

# Build
docker build -t containerized-api:latest .

# Run
docker run -d --name api -p 8080:8080 containerized-api:latest

# Verify
curl http://localhost:8080/health

# Logs
docker logs -f api

# Stop and remove
docker stop api && docker rm api
```

### Containerized API: run with Docker Compose

```bash
cd apps/containerized-api

docker compose up -d
curl http://localhost:8080/health
docker compose logs -f api
docker compose down
```

If port 8080 is already in use, change the host port in `compose.yaml` (e.g. `"8081:8080"`) or use the override approach: create a temporary `compose.override.yaml` that sets a different port, then `docker compose -f compose.yaml -f compose.override.yaml up -d`. Delete the override file when done.

### Containerized API: run the tests

Tests must be run from the `apps/containerized-api/` directory so Python can find the `app` package.

```bash
cd apps/containerized-api

# Stdlib unittest (no dependencies)
python3 -m unittest discover -v

# Or pytest, if installed
python3 -m pytest tests/ -v
```

All 9 tests should pass (health endpoint, info endpoint, 404 handling, trailing slashes).

### Containerized API: simulate the deploy pipeline locally

You can exercise the same commands that `app-deploy.yml` runs on EC2, without AWS, by simulating the remote host as a directory:

```bash
cd apps/containerized-api

# Build with an ECR-like tag (same shape the pipeline uses)
docker build -t 123456789012.dkr.ecr.us-east-1.amazonaws.com/containerized-api:sha-test .

# Simulate the remote host
REMOTE=/tmp/deploy-host-sim
rm -rf "$REMOTE"
mkdir -p "$REMOTE/opt/containerized-api"

# Save the image as a tarball (runner: pull + save)
docker save 123456789012.dkr.ecr.us-east-1.amazonaws.com/containerized-api:sha-test -o /tmp/api.tar

# Transfer to the "remote" (runner: scp)
cp compose.prod.yaml "$REMOTE/opt/containerized-api/"
cp /tmp/api.tar "$REMOTE/opt/containerized-api/"

# Deploy on the simulated host
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

This is the same load → compose up → health poll → verify path that runs on the EC2 host.

### Run the CI checks locally

To run the same checks CI runs on a pull request:

```bash
./scripts/pr-check.sh
```

This runs, in order: formatting check, validate-all, gitleaks (secret scan), and Checkov (security scan, strict mode). Each check can also be run individually via its own script.

### Common commands reference

| Goal | Command |
|------|--------|
| Format check | `terraform fmt -check -recursive` |
| Auto-format (local) | `./scripts/fmt-check.sh --fix` |
| Validate all | `./scripts/validate-all.sh` |
| Plan all (local) | `./scripts/plan-all.sh` |
| Security scan | `./scripts/checkov-scan.sh` |
| Strict security scan | `./scripts/checkov-scan.sh --strict` |
| PR check (all of the above + secret scan) | `./scripts/pr-check.sh` |
| Run the API (no Docker) | `cd apps/containerized-api && python3 -m app.main` |
| Run the API (Docker) | `cd apps/containerized-api && docker compose up -d` |
| Run the API tests | `cd apps/containerized-api && python3 -m unittest discover -v` |

## Structure


## Modules

### VPC (`modules/vpc/`)

Creates an isolated AWS VPC with:
- Public and private subnets across multiple AZs
- Internet Gateway
- Optional NAT Gateway (disabled by default to control costs)
- Public and private route tables

**Key inputs:** `name_prefix`, `cidr_block`, `az_count`, `public_subnet_cidrs`, `private_subnet_cidrs`, `enable_nat_gateway`

**Cost note:** NAT Gateway is optional and disabled by default. Enabling it incurs NAT Gateway + EIP + data processing charges.

### EC2 (`modules/ec2/`)

Creates a single EC2 instance with secure defaults:
- Root volume encryption enabled by default
- IMDSv2 required by default
- Public IP disabled by default
- Configurable root block device, user data, key pair, security groups

**Key inputs:** `ami` (required), `instance_type`, `name` (required), `subnet_id` (required), `security_group_ids`, `associate_public_ip`, `key_name`, `user_data`, `imdsv2_required`

### S3 (`modules/s3/`)

Creates an S3 bucket with secure defaults:
- AES256 server-side encryption
- Public access blocked
- BucketOwnerEnforced object ownership
- Optional versioning, lifecycle rules, and ACL

**Key inputs:** `bucket_name`, `versioning_enabled`, `sse_algorithm`, `lifecycle_rules`

### IAM (`modules/iam/`)

Creates an IAM role with optional policy and instance profile:
- Configurable assume role policy
- Optional IAM policy with least-privilege permissions
- Optional instance profile for EC2

**Key inputs:** `role_name`, `assume_role_policy`, `create_policy`, `policy_document`

### Security Group (`modules/security-group/`)

Creates a security group with configurable rules:
- Ingress and egress rules with CIDR, security group, or prefix list targets
- Default: no rules (all inbound denied)

**Key inputs:** `name`, `vpc_id`, `ingress_rules`, `egress_rules`

### ALB (`modules/alb/`)

Creates an Application Load Balancer:
- Internet-facing or internal
- Automatic or existing security group
- Default target group with health checks
- HTTP listener

**Key inputs:** `subnet_ids`, `vpc_id`, `internal`, `alb_ingress_rules`

### Auto Scaling (`modules/autoscaling/`)

Creates an Auto Scaling group with launch template:
- Configurable AMI, instance type, storage, networking
- Optional IAM instance profile
- Instance refresh with rolling strategy
- ELB or EC2 health checks

**Key inputs:** `subnet_ids`, `ami`, `instance_type`, `min_size`, `max_size`

### ECR (`modules/ecr/`)

Creates an ECR repository:
- Image scanning on push
- Optional lifecycle policy for image cleanup
- Optional repository policy for access control

**Key inputs:** `repository_name`, `image_tag_mutability`, `scan_on_push`, `lifecycle_policy`

## examples/

Each example is an independent Terraform root configuration that:
- Calls a reusable module via relative source path
- Configures its own AWS provider
- Has its own state (local by default, remote backend optional)
- Includes variables, outputs, versions, and README

All examples validate with:

```bash
cd examples/<name>
terraform fmt -check
terraform init -backend=false
terraform validate
```

## bootstrap/

### Terraform State (`bootstrap/terraform-state/`)

Creates the S3 bucket and DynamoDB table used for remote state across the project:

- Private S3 bucket with encryption and versioning
- DynamoDB table for state locking
- HTTPS-only bucket policy
- Optional IAM policy for least-privilege access

**Must be deployed first** before configuring remote backends in examples.

See `bootstrap/terraform-state/README.md` for details.

## apps/

### Infrastructure Lab (`apps/infrastructure-lab/`)

A complete, integrated AWS application that combines multiple reusable modules:

- **VPC** with public and private subnets across 2 AZs
- **Internet Gateway** for public subnet internet access
- **Application Load Balancer** (public, port 80)
- **2 Security Groups** — ALB SG (allows internet:80) and App SG (allows ALB SG:8080 only)
- **Auto Scaling Group** with launch template (private instances, no public IP)
- **EC2 instances** running a Python HTTP server with `/health` endpoint

**Cost-conscious design:** No NAT Gateway (saves ~$33/month). EC2 instances are t3.micro (free tier eligible).

**Total cost:** ~$24/month without free tier, ~$7.59/month with free tier (first 12 months).

See `apps/infrastructure-lab/README.md` for full architecture details, deployment instructions, and troubleshooting.

## Backend State

Each example now includes a `backend.tf` configured for remote state, but with placeholder bucket and DynamoDB table names. Before using remote state:

### Setup steps

1. **Deploy the bootstrap** to create the S3 bucket and DynamoDB table:

   ```bash
   cd bootstrap/terraform-state
   terraform apply -var="bucket_name=your-unique-bucket-name"
   ```

2. **Replace placeholders** in each `backend.tf`:

   - `BUCKET_NAME` → the actual S3 bucket name from the bootstrap output
   - `LOCK_TABLE_NAME` → the actual DynamoDB table name from the bootstrap output

3. **Initialize each example** with the remote backend:

   ```bash
   cd examples/vpc
   terraform init
   ```

   If you have existing local state, Terraform will prompt to migrate it. Review the prompt before confirming.

### Backend configuration

All backends use:

- The same S3 bucket (created by bootstrap)
- The same DynamoDB table (for state locking)
- Unique state keys per example
- Encryption enabled
- HTTPS enforced by the bucket policy

```
examples/vpc/terraform.tfstate
examples/ec2/terraform.tfstate
examples/s3/terraform.tfstate
examples/iam/terraform.tfstate
examples/security-group/terraform.tfstate
examples/alb/terraform.tfstate
examples/autoscaling/terraform.tfstate
examples/ecr/terraform.tfstate
```

### Why separate state files?

Each example has its own state file so that:

- **Isolation:** A change in one example only affects that example's state
- **Blast radius:** A corrupted state file only affects one configuration
- **Lifecycle:** You can destroy one example without affecting others

See `bootstrap/terraform-state/README.md` for full details on the backend infrastructure and state locking.

## AWS Cost Awareness

- NAT Gateway: ~$0.045/hour + EIP charges + data processing
- EC2 instances: hourly rate depends on instance type
- EBS volumes: per-GiB-month pricing
- ALB: ~$0.0225/hour + LCU charges
- ECR: ~$0.10/GiB-month storage
- Always run `terraform plan` before `terraform apply`
- Always `terraform destroy` when finished with lab resources

## Project status

This library is complete. It contains:

- **8 reusable modules** under `modules/` (VPC, EC2, S3, IAM, security-group, ALB, autoscaling, ECR)
- **8 examples** under `examples/` demonstrating each module
- **Bootstrap infrastructure** (`bootstrap/terraform-state/`) for secure remote state
- **2 integrated apps** under `apps/` (infrastructure-lab, containerized-api)
- **Full CI/CD pipeline**: PR validation, push validation, Docker CI, Docker Publish, Terraform CD, Application Deploy
- **Local helper scripts** in `scripts/` for validate, fmt check, plan, and security scan

### What is not included

- **Screenshots:** The `screenshots/` directory and screenshot section are defined in the README, but no images have been added yet. Add them as you deploy the infrastructure and capture AWS Console views.
- **Pre-built modules for every AWS service:** This library focuses on the modules needed for the integrated apps. Add more modules as needed.

## Conventions

- Reusable modules live in `modules/` and do NOT own state or configure providers
- Examples live in `examples/` and are independent root configurations
- Bootstrap configs live in `bootstrap/` and set up shared infrastructure
- Applications live in `apps/`
- Each independent root configuration gets its own unique state key
- State files, `.terraform/`, and secrets are gitignored
- `.terraform.lock.hcl` files in `examples/` and `bootstrap/` should be committed
- `.terraform.lock.hcl` files in `modules/` are gitignored (transitional artifacts)

## Dependabot

Automated dependency updates are configured in `.github/dependabot.yml`.

### What it updates

| Ecosystem | Directory | Schedule | Group | Limits |
|-----------|-----------|----------|-------|--------|
| GitHub Actions | `/` | Weekly (Monday) | `github-actions` | 5 open PRs max |
| Terraform (AWS provider) | `/` | Weekly (Monday) | `terraform-providers` | 5 open PRs max |

### How it works

- Dependabot scans `.github/workflows/*.yml` for action references and `versions.tf` files for provider constraints
- When a new version is available, Dependabot opens a PR with the update
- PRs are labeled (`dependencies`, `ci-cd` or `terraform`)
- PRs go through the normal CI validation (format + validate + security scan)
- PRs are **not auto-merged** — they require review and approval

### Grouping

Updates are grouped to reduce PR volume:

- All GitHub Actions updates arrive in a single PR (`github-actions` group)
- All AWS provider updates arrive in a single PR (`terraform-providers` group)
- Only minor and patch updates are grouped — major updates would break version constraints and are excluded

### Version constraints

The AWS provider is constrained to `>= 5.0, < 6.0` in all modules and examples. Dependabot will only suggest 5.x versions. A 6.x release would not match the constraint and would not trigger a PR.

To update the provider version constraint across the project, update it in each `versions.tf` file.

### Disabling or adjusting

To change the update schedule, edit `.github/dependabot.yml`. To disable Dependabot entirely, delete the file or set `open-pull-requests-limit: 0`.

See [Dependabot documentation](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates) for details.

## Terraform CD

The `terraform-deploy.yml` workflow deploys AWS infrastructure from approved configurations. It is **manual only** — triggered via `workflow_dispatch`, never on push or pull request.

### How it works

1. **Select configuration** — choose which Terraform root to deploy from a dropdown
2. **Authenticate** — GitHub OIDC requests temporary AWS credentials (no long-lived keys)
3. **Plan** — `terraform init` → `validate` → `fmt check` → `plan`
4. **Review** — plan is saved as an encrypted artifact for inspection
5. **Approve** — manual approval via GitHub Environment (required by default)
6. **Apply** — the exact plan from step 3 is applied
7. **Verify** — outputs are shown and a deployment summary is written

### Prerequisites

Before the CD workflow can deploy anything:

1. **Deploy the bootstrap infrastructure** to create the S3 state bucket and DynamoDB lock table
2. **Replace placeholder values** in each `backend.tf` with the actual bucket name and table name
3. **Set up GitHub OIDC trust** in AWS (create OIDC provider, create IAM role, add trust policy)
4. **Store the role ARN** in GitHub Secrets as `AWS_ROLE_ARN`
5. **Configure the GitHub Environment** `terraform-deployment` with required reviewers

Full setup instructions are in `.github/workflows/deploy-readme.md`.

### Security

- **No long-lived AWS keys:** Authentication is via OIDC, issuing short-lived tokens
- **Repository-scoped trust:** The IAM role can only be assumed from this repository on `main`
- **Manual approval:** Deployments require approval before applying (configurable via GitHub Environment)
- **Exact plan apply:** The apply uses the reviewed plan artifact, preventing drift
- **No destroy support:** This workflow does not support `terraform destroy`

### Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `configuration` | `examples/vpc` | Which Terraform root to deploy |
| `extra_vars` | `{}` | Extra variables as JSON |
| `auto_apply` | `false` | Skip approval and apply immediately |
| `environment_name` | `terraform-deployment` | GitHub Environment for approval |

### Files

- `.github/workflows/terraform-deploy.yml` — the deployment workflow
- `.github/workflows/deploy-readme.md` — setup guide and IAM permission documentation

See [deploy-readme.md](.github/workflows/deploy-readme.md) for complete setup instructions, IAM policy examples, and troubleshooting.

## Docker CI

The `docker-ci.yml` workflow validates the containerized application on pull requests and pushes affecting `apps/containerized-api/**`.

### Jobs

| Job | What it verifies |
|-----|------------------|
| **Application Tests** | 9 unit tests for `/health`, `/info`, and 404 handling |
| **Build Image** | Multi-stage Docker build succeeds; image exported as artifact for reuse |
| **Compose Test** | `docker compose up -d` starts the service, health check passes, and all endpoints respond correctly |
| **Trivy Scan** | Image scanned for vulnerabilities; SARIF uploaded to GitHub code scanning |

### Trivy policy

- **CRITICAL (fixable)** — blocks the build
- **HIGH (fixable)** — reported via SARIF and job summary, does not block
- **Unfixed** — ignored (nothing actionable)

The split exists because base images routinely carry HIGH findings in OS packages the application cannot control. Blocking on those would keep CI permanently red.

### What Docker CI does not do

- Does not deploy to AWS
- Does not publish images to a registry
- Does not modify any infrastructure

Publishing is handled separately by `docker-publish.yml` on `main` only.

## Docker Publish

The `docker-publish.yml` workflow publishes tested images to Amazon ECR. It runs only when Docker CI completes successfully on `main` (via `workflow_run`) or when manually dispatched.

### Why publish only after CI succeeds

Publishing is triggered by the completion of Docker CI, not by a push directly. This means an image reaches the registry only if it already passed:

- Application unit tests
- Docker build
- Docker Compose integration test
- Trivy vulnerability scan

The publish workflow pushes the **exact image artifact** that Docker CI built — not a rebuild — so the published bytes are identical to the tested image.

### Tags

| Tag | Purpose |
|-----|---------|
| `sha-<commit>` | Immutable, canonical, used by deployments |
| `latest` | Convenience, updated on every publish |

Deployments pin to the `sha-<commit>` tag. The `latest` tag is for convenience only.

### Required secrets

| Secret | Purpose |
|--------|---------|
| `AWS_ROLE_ARN` | OIDC role with ECR push permissions |
| `ECR_REPO_URI` | Full ECR repository URI |
| `AWS_REGION` | (optional) default `us-east-1` |

### What Docker Publish does not do

- Does not deploy to EC2
- Does not modify any infrastructure
- Does not run Terraform

Deployment is handled separately by `app-deploy.yml`.

## Application Deploy

The `app-deploy.yml` workflow deploys the containerized API to an EC2 host via SSH. It can be triggered manually or automatically after a successful Docker Publish.

### Triggers

| Trigger | When |
|---------|-------|
| Manual dispatch | You choose the image tag and target host |
| After Docker Publish (main) | Deploys the just-published `sha-<commit>` image automatically |

Both require approval through the GitHub Environment `production` (configure required reviewers in Settings → Environments).

### How the deployment works

The GitHub Actions runner acts as a bridge to ECR. The deploy target EC2 host has **no AWS credentials and no ECR access**.

1. The runner authenticates to ECR via OIDC
2. The runner pulls the image from ECR
3. The runner saves the image as a tarball and transfers it to the host via `scp`
4. The host loads the tarball, writes a `.env` file, and runs `docker compose up -d`
5. The host is verified: health check, `/health`, `/info`, and 404 handling

### Rollback

Before deploying, if the previous image is cached on the host, the script saves it as a tarball. On verification failure, it restores the previous image from the tarball and re-verifies. This makes rollback independent of ECR access from the host.

### Required secrets

| Secret | Purpose |
|--------|---------|
| `EC2_HOST` | Deploy target hostname or IP |
| `EC2_USER` | SSH user (default `ec2-user`) |
| `EC2_SSH_PRIVATE_KEY` | SSH private key with access to the host |
| `ECR_REPO_URI` | Full ECR repository URI |
| `AWS_ROLE_ARN` | OIDC role with ECR read (`GetAuthorizationToken`) |
| `AWS_REGION` | (optional) default `us-east-1` |

### Deploy target prerequisites

- Docker Engine installed
- Docker Compose v2 plugin (`docker compose`)
- Reachable from GitHub Actions runners (directly or via a bastion)

### Security notes

- The SSH private key is written to a 600 file and never printed to logs.
- The SSH host key is scanned at deploy time; pin it for production.
- ECR credentials are short-lived (OIDC) and scoped to `GetAuthorizationToken`.

## What CI/CD does not do

None of the CI/CD workflows:

- Run `terraform apply` or `terraform destroy`
- Modify any AWS infrastructure
- Use long-lived AWS credentials
- Deploy to production without approval

## AWS Console reference

This section maps each Terraform-managed resource to where you will find it in the AWS Console. Use it to confirm that the infrastructure Terraform created matches what you expect to see.

The Console URL base is `https://<region>.console.aws.amazon.com/` — for example, `https://us-east-1.console.aws.amazon.com/` for us-east-1. Many resources are reachable from the global Services menu or from their region-specific landing page.

### Bootstrap (terraform-state)

| Resource | AWS Console location | What to look for |
|----------|---------------------|------------------|
| S3 bucket | Services → S3 → search the bucket name | A private bucket with the `terraform-state` prefix. Object ownership is Bucket owner enforced. |
| Bucket encryption | S3 → bucket → Settings → Default encryption | Default encryption enabled, AES256 (or AWS KMS if configured). |
| Bucket versioning | S3 → bucket → Settings → Versioning | Versioning enabled. |
| Bucket policy (HTTPS-only) | S3 → bucket → Permissions → Bucket policy | A policy that denies non-SSL requests (http403 on plain HTTP). |
| DynamoDB table | Services → DynamoDB → Tables | A table with the lock-table name. Partition key is `LockID` (string). Used for state locking. |

### VPC (examples/vpc, apps/infrastructure-lab)

| Resource | AWS Console location | What to look for |
|----------|---------------------|------------------|
| VPC | Services → VPC → Virtual Private Cloud → Your VPCs | A VPC with the configured CIDR, state `available`. |
| Subnets | VPC → Subnets | Public subnets (map public IP on launch) and private subnets (no public IP). Each in a different AZ. |
| Internet Gateway | VPC → Internet Gateways | An IGW attached to the VPC, state `attached`. |
| Route tables | VPC → Route Tables | Public route table with a default route (`0.0.0.0/0`) to the IGW; private route table with no internet route. |
| NAT Gateway (if enabled) | VPC → NAT Gateways | A NAT GW in a public subnet, associated with an Elastic IP. Optional — disabled by default to control cost. |

### EC2 (examples/ec2, modules/ec2)

| Resource | AWS Console location | What to look for |
|----------|---------------------|------------------|
| Instance | Services → EC2 → Instances | An instance in the target subnet, in `running` state, with the configured instance type. Public IP is disabled by default. |
| Instance details | EC2 → Instances → select instance → Details | AMI, IAM instance profile, security groups, root volume encryption, metadata options (IMDSv2 required). |
| Key pair | EC2 → Key Pairs | The key pair used to SSH (if configured). The private key is not stored in AWS. |
| Security group | EC2 → Security Groups | The SG attached to the instance. Inbound rules reflect what was configured (e.g., allow ALB SG on the app port). |
| EBS volume | EC2 → Volumes | The root volume, encrypted, in the same AZ as the instance. |

### S3 bucket (examples/s3, modules/s3)

| Resource | AWS Console location | What to look for |
|----------|---------------------|------------------|
| Bucket | Services → S3 → search the bucket name | A private bucket with public access blocked. |
| Encryption | S3 → bucket → Settings → Default encryption | Server-side encryption enabled (AES256 or KMS). |
| Versioning | S3 → bucket → Settings → Versioning | Versioning as configured. |
| Block public access | S3 → bucket → Permissions → Block public access | All four block settings enabled. |
| Object ownership | S3 → bucket → Permissions → Object ownership | Bucket owner enforced. |

### IAM (examples/iam, modules/iam)

| Resource | AWS Console location | What to look for |
|----------|---------------------|------------------|
| Role | Services → IAM → Access management → Roles | A role with the configured name and trust policy (who can assume it). |
| Policy (if created) | IAM → Access management → Policies | An inline or managed policy attached to the role, with the configured permissions. |
| Instance profile | IAM → Access management → Instance profiles | An instance profile containing the role (if created). Attached to EC2 at launch. |

### Security Group (examples/security-group, modules/security-group)

| Resource | AWS Console location | What to look for |
|----------|---------------------|------------------|
| Security group | EC2 → Security Groups | A SG in the target VPC with the configured name. Inbound and egress rules reflect the input (default: no inbound rules). |

### ALB (examples/alb, modules/alb, apps/infrastructure-lab)

| Resource | AWS Console location | What to look for |
|----------|---------------------|------------------|
| Load Balancer | EC2 → Load Balancing → Load Balancers | An ALB in the target subnets, state `active`, with the configured scheme (internet-facing or internal). |
| Listeners | EC2 → Load Balancers → select ALB → Listeners | A listener on port 80 (HTTP) forwarding to the target group. |
| Target group | EC2 → Load Balancing → Target Groups | A target group with the configured port and health check. Targets show as `healthy` after registration. |
| Health checks | EC2 → Target Groups → select group → Health checks | The health check settings (path, port, interval, timeout, healthy/unhealthy thresholds). |

### Auto Scaling (examples/autoscaling, modules/autoscaling, apps/infrastructure-lab)

| Resource | AWS Console location | What to look for |
|----------|---------------------|------------------|
| Auto Scaling group | EC2 → Auto Scaling → Auto Scaling Groups | An ASG in the target VPC/subnets, with the configured min/max/desired capacity. |
| Launch template | EC2 → Instances → Launch templates | The template with the configured AMI, instance type, storage, security groups, and subnet. |
| Instances | EC2 → Instances | The EC2 instances launched by the ASG, in `running` state, tagged by the ASG. |
| Instance refresh | ASG → Instance refresh | If configured, a rolling update of instances. |

### ECR (examples/ecr, modules/ecr)

| Resource | AWS Console location | What to look for |
|----------|---------------------|------------------|
| Repository | Services → ECR → Repositories | A repository with the configured name, image tag mutability, and scan-on-push enabled. |
| Image scan results | ECR → Repositories → select repo → select image → Scan details | Vulnerability scan results (OS packages and language packages). The CI Trivy scan produces SARIF uploaded to the GitHub Security tab; ECR scan-on-push results appear here. |
| Lifecycle policy (if set) | ECR → Repositories → select repo → Lifecycle policy | Rules that prune old images by count or age. |

### Containerized API on EC2 (after app-deploy)

| Resource | AWS Console location | What to look for |
|----------|---------------------|------------------|
| EC2 instance | EC2 → Instances | The deploy target instance, in `running` state. |
| Docker containers | SSH to the instance, then `docker ps` | The `containerized-api` container, up and healthy. Not visible in the Console — check on the instance. |
| ALB health (if behind ALB) | EC2 → Load Balancing → Target Groups → select TG → Targets | The container's host registered as a target, health `healthy`. |

### Where to look first

If you just deployed the **bootstrap**, start here to confirm the state backend exists:

1. S3 → search the bucket name → confirm it exists, is private, has default encryption and versioning.
2. DynamoDB → Tables → confirm the lock table exists with `LockID` partition key.

If you deployed the **infrastructure-lab**, the highest-value views are:

1. VPC → Your VPCs → the lab VPC (CIDR, state available).
2. VPC → Subnets → public + private subnets across 2 AZs.
3. EC2 → Load Balancers → the ALB (active, internet-facing, port 80 listener).
4. EC2 → Load Balancing → Target Groups → the TG (healthy targets).
5. EC2 → Auto Scaling → the ASG and its instances.

If you published the **containerized API**, confirm the image reached ECR:

1. ECR → Repositories → the `containerized-api` repo.
2. Select the repo → choose the `sha-<commit>` or `latest` image → Scan details.

### Screenshot source locations

The screenshots section (above) lists the exact filenames and where to place them. Each screenshot should be taken from the Console location listed in this section. For example, the `s3-bucket-overview.png` screenshot should be taken from S3 → bucket list, and the `alb-listener.png` screenshot from EC2 → Load Balancers → the ALB → Listeners.

## Local helper scripts

The `scripts/` directory contains helpers for local development and CI-like checks.

| Script | Purpose |
|--------|--------|
| `scripts/validate-all.sh` | `terraform init -backend=false` + `terraform validate` for every root configuration |
| `scripts/fmt-check.sh` | `terraform fmt -check -recursive` (use `--fix` to rewrite in place) |
| `scripts/plan-all.sh` | Generate `terraform plan` for every root configuration, write plans + text to `plans/` |
| `scripts/checkov-scan.sh` | Run Checkov against `examples/` and `bootstrap/` with the project's skip list |

All scripts are read-only by default (except `--fix` on fmt-check). They mirror the checks that run in CI.

### Quick start

```bash
# Format check
./scripts/fmt-check.sh

# Fix formatting (local only)
./scripts/fmt-check.sh --fix

# Validate all configurations
./scripts/validate-all.sh

# Generate plans (no apply)
./scripts/plan-all.sh

# Security scan
./scripts/checkov-scan.sh

# Strict scan (fail on findings)
./scripts/checkov-scan.sh --strict
```

## Screenshots

This project documents AWS Console and GUI views to help learners connect the Terraform code to what they will see in the AWS Console. Screenshots are optional — the code works without them — but they make thedocumentation much clearer.

### Where screenshots belong

Add screenshots to a `screenshots/` directory at the project root, organized by feature:

```
screenshots/
├── bootstrap/
│   ├── s3-bucket-overview.png          # S3 bucket created by bootstrap
│   ├── s3-bucket-encryption.png        # Default encryption enabled
│   └── dynamodb-table.png              # DynamoDB lock table
├── vpc/
│   ├── vpc-overview.png                # VPC with subnets in AWS Console
│   └── vpc-flow-logs.png               # (optional) VPC Flow Logs
├── ec2/
│   └── ec2-instance.png                # EC2 instance in Running state
├── ecr/
│   ├── ecr-repository.png              # ECR repository with scanning on
│   └── ecr-image-scan-results.png      # Vulnerability scan results
├── alb/
│   └── alb-listener.png                # ALB listener on port 80
├── autoscaling/
│   └── asg-instances.png              # ASG with running instances
├── infrastructure-lab/
│   ├── lab-architecture.png            # Architecture diagram (VPC → ALB → ASG)
│   ├── alb-target-group.png            # Target group healthy
│   └── ec2-ssh.png                     # EC2 instance details
└── container-deploy/
    ├── ecr-repo-published.png          # Published image in ECR
    ├── ec2-container-running.png        # Container running on EC2
    └── health-check-passing.png         # ALB health checks passing
```

### How to add a screenshot

1. Deploy the relevant infrastructure (e.g., bootstrap, an example, or the lab app)
2. Open the AWS Console and navigate to the resource (S3, EC2, ECR, ALB, etc.)
3. Take a screenshot of the key view (overview, properties, or health status)
4. Save it to `screenshots/<feature>/<description>.png` using lowercase-hyphenated names
5. Add a reference to it in the relevant README, for example:

   ```markdown
   ![S3 bucket overview](screenshots/bootstrap/s3-bucket-overview.png)
   ```

### What each screenshot should show

Focus on the view that confirms the Terraform-managed setting:

| Screenshot | What it proves |
|------------|----------------|
| S3 bucket overview | Bucket exists, private, with versioning |
| S3 encryption | Default encryption (AES256) is enabled |
| DynamoDB table | Lock table exists with partition key |
| VPC overview | VPC, subnets, route tables created as configured |
| EC2 instance | Instance running, in the right subnet, with the right type |
| ECR repository | Repository exists, scanning on push enabled |
| ECR scan results | Image scan results (vulnerabilities found or clean) |
| ALB listener | Listener on port 80, forwarding to target group |
| ASG instances | Instances in the ASG, healthy |
| Target group | Target group healthy, targets registered |
| Container running | Container on EC2, health check passing |

### Screenshot guidelines

- **Annotate if helpful:** Use arrows or boxes to highlight the key element (e.g., "Encryption: AES256", "Status: Healthy")
- **Show the right view:** A single clear screenshot is better than a sequence. Pick the view that most directly shows the configured setting.
- **Privacy:** Do not include account IDs, access keys, or other sensitive values in screenshots. The AWS Console often masks these, but double-check.
- **Keep them current:** If a workflow or module changes, update or replace the relevant screenshots.
- **Size:** Resize large screenshots to keep the repository small (aim for under 500KB each, 1280px wide is usually enough).

### When screenshots are not available

If you cannot take screenshots (no AWS access, no GUI), that is fine. The screenshots section documents where they would go, and the code is fully functional without them. A future contributor with AWS access can add them.

### Suggested first screenshots

If you deploy the bootstrap and the infrastructure-lab app, these are the highest-value screenshots to add first:

1. `screenshots/bootstrap/s3-bucket-overview.png` — proves the state bucket exists
2. `screenshots/bootstrap/dynamodb-table.png` — proves the lock table exists
3. `screenshots/infrastructure-lab/lab-architecture.png` — architecture diagram of the lab
4. `screenshots/infrastructure-lab/alb-target-group.png` — proves the ALB target group is healthy
5. `screenshots/infrastructure-lab/ec2-ssh.png` — EC2 instance details

These five screenshots cover the core infrastructure and the integrated app, and give learners a visual reference for what the Terraform code creates.


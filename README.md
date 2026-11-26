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

## Run and test

### Requirements

- Terraform 1.5+ for infrastructure.
- Python 3.11+ for the API and unit tests.
- Docker (optional) for container testing.
- AWS credentials are needed to plan/apply AWS resources, not for formatting, validation, or API unit tests.

### Local checks

From the project root:

```bash
terraform fmt -check -recursive
./scripts/validate-all.sh
cd apps/containerized-api && python3 -m unittest discover -v
```

`validate-all.sh` runs Terraform init with `-backend=false` and validates the root configurations. It does not create AWS resources. The API suite should report 9 passing tests.

For local security/PR checks, install Checkov in a virtual environment and the Gitleaks CLI (Go required):

```bash
python3 -m venv /tmp/terraform-aws-modular-tools
source /tmp/terraform-aws-modular-tools/bin/activate
python -m pip install checkov
go install github.com/zricethezav/gitleaks/v8@latest
export PATH="$(go env GOPATH)/bin:$PATH"
./scripts/pr-check.sh
```

The PR check runs formatting, validation, Gitleaks, and strict Checkov. It does not deploy infrastructure.

### Run the API

Without Docker, from `apps/containerized-api`:

```bash
APP_PORT=8081 python3 -m app.main
```

In another terminal, expect `/health` and `/info` to return 200 and an unknown path to return 404:

```bash
curl -i http://localhost:8081/health
curl -i http://localhost:8081/info
curl -i http://localhost:8081/not-found
```

Stop the server with Ctrl+C. To try the container, build with `docker build -t containerized-api .`, run with `docker run --rm -d --name api -p 8081:8080 containerized-api`, then test the same URLs and stop it with `docker stop api`. Choose a free host port if 8081 is occupied.

### Plan and apply AWS resources

Each example/app directory is an independent Terraform root. `terraform plan` previews changes; it creates nothing. `terraform apply` creates only the resources in that root and asks for confirmation. AWS charges may apply. Use `terraform destroy` in the same root when you are finished.

For example, the VPC root can be planned locally:

```bash
cd examples/vpc
terraform init -backend=false
terraform plan
```

Only run `terraform apply` if you intend to create the VPC, subnets, internet gateway, and route tables in AWS; Terraform will show the plan and ask you to confirm. For the EC2 example, first deploy or select an existing VPC, then provide its `vpc_id`, a `subnet_id`, and a region-valid AMI. See [examples/ec2/README.md](examples/ec2/README.md) for its exact inputs and commands. That example creates one `t3.micro` EC2 instance, an attached security group, and an encrypted 10 GiB root volume; public IP assignment is off by default. It does not create the VPC.

Remote state is optional for local learning. To use it, deploy `bootstrap/terraform-state` first and configure the backend values; see [Backend State](README.md#backend-state).

## Structure

Reusable modules, standalone examples, bootstrap infrastructure, and apps are kept in separate directories and Terraform roots.

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

## CI/CD

Local `./scripts/pr-check.sh` runs checks on your machine; it does not start GitHub Actions or deploy to AWS. GitHub workflows run from repository events:

| Workflow | Trigger | Effect |
|----------|---------|--------|
| Terraform PR validation | Pull request to `main` changing Terraform, modules, examples, bootstrap, infrastructure-lab, or workflow files | Format, validate, and Checkov checks; no apply |
| Terraform push validation | Matching changes pushed to `main` | Format and validate; no apply |
| Docker CI | PR or push to `main` changing `apps/containerized-api/**` | Unit tests, image build, Compose test, Trivy scan; no AWS deployment |
| Docker Publish | Successful Docker CI on `main`, or manual dispatch | Publishes the tested image to ECR (`sha-<commit>` and `latest`) |
| Application Deploy | Manual dispatch, or after successful Docker Publish on `main` | Deploys the API to a configured EC2 host; production environment approval is required |
| Terraform Deploy | Manual dispatch only | Plans a selected Terraform root, waits for approval, then applies the reviewed plan |

Terraform Deploy requires AWS OIDC, the configured `terraform-deployment` GitHub Environment, and remote-state setup. Application Deploy needs the ECR/AWS and EC2 SSH secrets described in [deploy-readme.md](.github/workflows/deploy-readme.md). CI does not automatically apply Terraform on a push or pull request.

### Trigger workflows in GitHub

**Automatic checks:** Push a branch and open a PR targeting `main`. Matching Terraform changes run Terraform PR Validation; changes under `apps/containerized-api/` also run Docker CI. After merge, matching changes run push validation. A successful Docker CI run on `main` starts Docker Publish, followed by Application Deploy.

**Manually deploy infrastructure:**

1. Configure AWS OIDC, the `AWS_ROLE_ARN` secret, the `AWS_REGION` variable, the remote-state backend, and required reviewers for the `terraform-deployment` environment.
2. Open **Actions → Terraform Deploy → Run workflow**, select branch `main`, choose one configuration, and enter required variables as JSON in `extra_vars` (for example: `{"vpc_id":"vpc-...","subnet_id":"subnet-...","ami":"ami-..."}` for EC2).
3. Start the run. Wait for the Plan job, download its `tfplan` artifact, and inspect it with `terraform show tfplan`.
4. If the plan is correct, approve the waiting Apply job in the `terraform-deployment` environment. It applies that exact plan. If there are no changes, Apply is skipped.

**Manually publish or deploy the API:** In **Actions**, choose **Docker Publish → Run workflow** and optionally enter a successful Docker CI commit SHA from `main`. Then choose **Application Deploy → Run workflow**, select the image tag (prefer `sha-<commit>`), and provide host overrides only if needed. Approve the `production` environment. These workflows require the configured ECR/AWS secrets and a reachable EC2 host with Docker and Compose.

## AWS Deployment Flow

This is the AWS-side flow; local tests and PR checks do not create or change AWS resources.

### Infrastructure deployment

1. In GitHub, open **Actions → Terraform Deploy → Run workflow** and select one Terraform root.
2. The runner uses GitHub OIDC to assume the configured AWS IAM role. No long-lived AWS access key is used.
3. Terraform reads/writes state in the bootstrap S3 bucket and uses DynamoDB for state locking. The bootstrap and real backend names must be configured first.
4. The Plan job creates an artifact before the Apply job waits for approval. Review the artifact before approving the `terraform-deployment` environment.
5. After approval, the Apply job applies that exact plan. It creates or updates only the selected root's resources; it does not deploy every example.

### Container application deployment

1. A pull request or push to `main` that changes `apps/containerized-api/**` starts **Docker CI**. It runs unit tests, builds the image, tests it with Compose, and scans it with Trivy. This stage does not access AWS.
2. After Docker CI succeeds on `main`, **Docker Publish** uses OIDC to authenticate to AWS and publishes that exact tested image to the configured ECR repository.
3. **Application Deploy** runs after a successful publish on `main`, or can be started manually. After `production` approval, the runner retrieves the image from ECR and transfers it over SSH to the configured EC2 host.
4. The host loads the image and runs it with Docker Compose. The workflow checks `/health`, `/info`, and the 404 response.

The EC2 host must already exist and have Docker/Compose installed. The host itself does not need ECR access or AWS credentials. Application Deploy moves the application; Terraform Deploy creates infrastructure. They are separate workflows.

### AWS services used

| AWS service | Role in this project |
|-------------|----------------------|
| IAM OIDC role | Gives GitHub Actions temporary, scoped AWS credentials. |
| IAM roles and policies | Demonstrated by the IAM example; grant AWS permissions to workloads. The GitHub OIDC role is separate. |
| S3 + DynamoDB | The bootstrap S3 bucket stores remote Terraform state; DynamoDB locks it during operations. The S3 example creates a separate storage bucket. |
| VPC, subnets, Internet Gateway, route tables | Provide the network used by the examples and infrastructure lab. |
| Security groups | Control allowed inbound and outbound traffic for instances and load balancers. |
| EC2 | Runs the example instance or the configured API deployment host. |
| ALB + target group | Accepts web traffic and checks application targets in the infrastructure lab. |
| Auto Scaling + launch template | Creates and manages the infrastructure lab's EC2 instances. |
| ECR | Stores versioned container images published by Docker Publish. |

Each Terraform root manages its own resources and state. A plan alone changes nothing; resources appear in AWS only after an approved Terraform apply or the applicable deployment workflow succeeds.

## AWS Console reference

Select **us-east-1** for the examples in this README. A Terraform plan is not a deployment; resources appear in the Console only after apply or a successful deployment workflow.

| Terraform configuration | AWS Console locations |
|--------------------------|------------------------|
| `examples/vpc` | VPC → Your VPCs, Subnets, Internet Gateways, Route Tables |
| `examples/ec2` | EC2 → Instances, Security Groups, Volumes |
| `bootstrap/terraform-state` | S3 → bucket; DynamoDB → Tables |
| `examples/ecr` / Docker Publish | ECR → Repositories → images |
| `apps/infrastructure-lab` | VPC resources; EC2 → Load Balancers, Target Groups, Auto Scaling Groups, Instances |

The local API and Docker tests are not AWS resources. A container deployed to EC2 is checked on the host (for example, with `docker ps`), not shown as a separate AWS Console resource.

## Helper scripts

- `./scripts/fmt-check.sh` checks Terraform formatting (`--fix` rewrites files).
- `./scripts/validate-all.sh` validates Terraform roots without applying.
- `./scripts/pr-check.sh` runs formatting, validation, Gitleaks, and strict Checkov.
- Use `terraform plan` from an individual root to review its changes. `plan-all.sh` is not recommended until its required-input and output-path handling is corrected.

## Screenshot plan

Capture screenshots only after the relevant test or deployment succeeds. Save them under `screenshots/` and embed them in this README when the image files exist.

1. **CI evidence** — GitHub repository → Actions → show successful Terraform PR validation and Docker CI runs. Save as `screenshots/ci/terraform-pr-checks.png` and `screenshots/ci/docker-ci.png`.
2. **Existing VPC** — AWS Console in `us-east-1` → VPC → Your VPCs, then Subnets/Route Tables. Show the VPC ID, public/private subnets, and routes. Save as `screenshots/vpc/vpc-overview.png` and `screenshots/vpc/subnets-and-routes.png`.
3. **EC2 example (after apply)** — EC2 → Instances → select the `ec2-example-instance`; show running state, instance type, subnet, and security group. Then show the security-group inbound rule and encrypted root volume. Save as `screenshots/ec2/instance-details.png`, `screenshots/ec2/security-group.png`, and `screenshots/ec2/encrypted-volume.png`.
4. **Bootstrap (only if deployed)** — S3 bucket encryption/versioning and the DynamoDB lock table. Save as `screenshots/bootstrap/state-bucket.png` and `screenshots/bootstrap/lock-table.png`.
5. **Integrated lab (optional, after apply)** — ALB active, target group with healthy targets, and Auto Scaling group instances. These resources may incur charges. Save under `screenshots/infrastructure-lab/`.
6. **API evidence** — optionally capture the successful `/health`, `/info`, and 404 checks in a terminal as `screenshots/api/local-smoke-test.png`. Local API output will not appear in AWS.

Before committing screenshots, hide account IDs, public IPs, credentials, private keys, and other sensitive values. A plan alone is not evidence that resources exist; only capture AWS resource pages after apply.

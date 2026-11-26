# IAM Example

This is a working example of the reusable IAM module.

It creates:
- 1 IAM role
- 1 IAM policy (attached to the role)
- Optionally: 1 IAM instance profile (for EC2)

## What this example is for

It shows how a root configuration calls `modules/iam` and uses its outputs.

The module source path from this example is `../../modules/iam`.

IAM resources are **free** — there is no charge for roles, policies, or instance profiles.

## Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform `>= 1.5`
- Credentials with permission to create IAM roles, policies, and instance profiles

## Commands

### 1) Formatting and validation, no AWS needed

```bash
cd examples/iam

terraform fmt -check
terraform fmt
terraform init -backend=false
terraform validate
```

- `terraform fmt -check` confirms formatting.
- `terraform fmt` fixes formatting if needed.
- `terraform init -backend=false` initializes providers and the module without requiring a remote backend.
- `terraform validate` confirms the configuration is structurally valid.

### 2) Plan only

```bash
terraform plan
```

Read the plan before anything else. It should show:
- 1 IAM role
- 1 IAM policy (if `create_policy = true`)
- 1 IAM instance profile (if `create_instance_profile = true`)

### 3) Apply with approval

```bash
terraform apply
```

Do not run this unless you want real IAM resources created.

### 4) Read outputs

```bash
terraform output
terraform output -raw role_arn
terraform output -raw policy_arn
```

### 5) Destroy when finished

```bash
terraform destroy
```

If the instance profile is attached to a running EC2 instance, destroy will fail. Detach the instance profile first.

## Cost warning

IAM roles, policies, and instance profiles are **free**. There is no cost for creating or using these resources.

## Module inputs used

| Input | Value source |
|-------|--------------|
| `role_name` | `var.role_name` |
| `assume_role_policy` | constructed from `var.assume_role_service` |
| `create_policy` | `var.create_policy` |
| `policy_document` | constructed from `var.policy_statements` |
| `policy_name` | `var.policy_name` |
| `policy_description` | `var.policy_description` |
| `create_instance_profile` | `var.create_instance_profile` |
| `max_session_duration` | `var.max_session_duration` |
| `tags` | merged from `var.tags` and `var.role_purpose` |

## Module outputs used

This example exposes:

- `role_name`
- `role_arn`
- `role_unique_id`
- `policy_arn`
- `instance_profile_name`
- `instance_profile_arn`

## Backend state

By default this example uses local state.

If you want a remote backend, configure it here and give this example its own unique backend key. For example:

```hcl
backend "s3" {
  bucket       = "your-terraform-state-bucket"
  key          = "examples/iam/terraform.tfstate"
  region       = "us-east-1"
  use_lockfile = true
  encrypt      = true
}
```

Do not store state inside `modules/iam/`.

## Artifacts you should not commit

From this directory, do not commit:

- `.terraform/`
- `terraform.tfstate`
- `terraform.tfstate.backup`

The repository `.gitignore` is set up to exclude these. If you ever see them showing up as untracked files, that usually means the example was initialized without a clean workspace or the `.gitignore` is not being read where you expect.

A root configuration's lock file, `.terraform.lock.hcl`, is expected to be committed once this example is initialized for real.

## Troubleshooting

If validation fails, check that your policy statements use valid IAM grammar. IAM policies use a specific JSON structure — not Terraform syntax.

If role creation fails with a name conflict, choose a different `role_name`. Role names must be unique within your AWS account.

If destroy fails because the instance profile is in use, detach it from any EC2 instances first, or manually delete the instance profile before running `terraform destroy` again.

## Notes

- The default policy in this example grants broad S3 access. Replace `policy_statements` with least-privilege permissions for your actual use case.
- The default assume role policy allows EC2 to assume the role. Change `assume_role_service` if you need a different service (e.g. `lambda.amazonaws.com`).
- Instance profiles are only needed for EC2. Leave `create_instance_profile = false` for roles used by Lambda, ECS, or other services.
- IAM policy documents use the IAM policy grammar. Use `jsonencode()` in Terraform to build them from expressions.

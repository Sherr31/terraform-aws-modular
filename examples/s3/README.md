# S3 Example

This is a working example of the reusable S3 module.

It creates a single S3 bucket with secure defaults:

- Server-side encryption (AES256)
- Public access blocked
- BucketOwnerEnforced object ownership
- Versioning disabled (to keep costs predictable)

## What this example is for

It shows how a root configuration calls `modules/s3` and uses its outputs.

The module source path from this example is `../../modules/s3`.

It is intentionally low cost by default:

- No versioning (no storage of old versions)
- No custom KMS key
- No public access (no website hosting, no public policies)

## Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform `>= 1.5`
- Credentials with permission to create S3 buckets

**Important:** S3 bucket names must be globally unique. The default `bucket_name` will fail because it is not unique. Change it before applying.

## Commands

### 1) Formatting and validation, no AWS needed

```bash
cd examples/s3

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

Read the plan before anything else. It should show one S3 bucket with encryption and public access block.

### 3) Apply with approval

```bash
terraform apply
```

Do not run this unless you want a real S3 bucket created.

**Before applying, change `bucket_name`** to something globally unique.

### 4) Read outputs

```bash
terraform output
terraform output -raw bucket_id
terraform output -raw bucket_domain_name
```

### 5) Destroy when finished

```bash
terraform destroy
```

If the bucket has objects in it, destroy will fail. Empty the bucket first or use `terraform state` to remove it.

## Cost warning

S3 is generally low cost for small buckets, but not free:

- Storage per GiB-month
- PUT/GET/COPY/POST/LIST requests
- Data transfer out to the internet
- If versioning is enabled, older versions also incur storage costs

Destroy the example when you are finished learning.

## Module inputs used

| Input | Value source |
|-------|--------------|
| `bucket_name` | `var.bucket_name` |
| `versioning_enabled` | `var.versioning_enabled` |
| `sse_algorithm` | `var.sse_algorithm` |
| `kms_key_id` | `var.kms_key_id` |
| `object_ownership` | `var.object_ownership` |
| `acl` | `var.acl` |
| `tags` | merged from `var.tags` and `var.bucket_purpose` |
| `lifecycle_rules` | `var.lifecycle_rules` |

## Module outputs used

This example exposes:

- `bucket_id`
- `bucket_arn`
- `bucket_domain_name`

The module also exports `bucket_region` and `bucket_name` if you need them.

## Backend state

By default this example uses local state.

If you want a remote backend, configure it here and give this example its own unique backend key. For example:

```hcl
backend "s3" {
  bucket       = "your-terraform-state-bucket"
  key          = "examples/s3/terraform.tfstate"
  region       = "us-east-1"
  use_lockfile = true
  encrypt      = true
}
```

Do not store state inside `modules/s3/`.

## Artifacts you should not commit

From this directory, do not commit:

- `.terraform/`
- `terraform.tfstate`
- `terraform.tfstate.backup`

The repository `.gitignore` is set up to exclude these. If you ever see them showing up as untracked files, that usually means the example was initialized without a clean workspace or the `.gitignore` is not being read where you expect.

A root configuration's lock file, `.terraform.lock.hcl`, is expected to be committed once this example is initialized for real.

## Troubleshooting

If validation fails with a missing required variable, check that you provided `bucket_name`.

If `terraform init` cannot find the module, confirm the source path is `../../modules/s3` from this directory.

If bucket creation fails with a name conflict error, choose a more unique `bucket_name`. S3 bucket names are globally unique across all AWS accounts.

## Notes

- S3 bucket names are globally unique. Plan your naming convention early.
- The default encryption is AES256 (S3-managed keys). Use `aws:kms` and `kms_key_id` if you need KMS-backed encryption with a specific key.
- Public access is blocked by default. Set all four `block_public_*` variables to `false` if you need public access, and understand the security implications first.
- Versioning is disabled by default. Enable it only when you need object history.

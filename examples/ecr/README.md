# ECR Example

This is a working example of the reusable ECR module.

It creates:
- 1 ECR repository
- 1 lifecycle policy (keeps last 10 images by default)

## What this example is for

It shows how a root configuration calls `modules/ecr` and uses its outputs.

The module source path from this example is `../../modules/ecr`.

## Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform `>= 1.5`
- Credentials with permission to create ECR repositories

## Commands

### 1) Formatting and validation, no AWS needed

```bash
cd examples/ecr

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
- 1 ECR repository
- 1 lifecycle policy

### 3) Apply with approval

```bash
terraform apply
```

Do not run this unless you want a real ECR repository created.

### 4) Read outputs

```bash
terraform output
terraform output -raw repository_url
```

The `repository_url` is what you use for `docker push` and `docker pull`.

### 5) Destroy when finished

```bash
terraform destroy
```

Deleting the repository also deletes all images in it. Make sure you don't need them.

## Cost warning

ECR is low cost for small repositories:

- **Storage:** ~$0.10/GiB-month in us-east-1
- **Data transfer:** outbound data transfer costs apply
- **Scanning:** free

A repository with a few small images costs less than $1/month.

**Always destroy when done with labs** to avoid storage charges.

## Module inputs used

| Input | Value source |
|-------|--------------|
| `repository_name` | `var.repository_name` |
| `image_tag_mutability` | `var.image_tag_mutability` |
| `scan_on_push` | `var.scan_on_push` |
| `encryption_type` | `var.encryption_type` |
| `kms_key_id` | `var.kms_key_id` |
| `lifecycle_policy` | `var.lifecycle_policy` |
| `repository_policy` | `var.repository_policy` |
| `tags` | merged from `var.tags` and `Purpose = "example"` |

## Module outputs used

This example exposes:

- `repository_id`
- `repository_arn`
- `repository_url`
- `repository_name`
- `registry_id`

## Backend state

By default this example uses local state.

If you want a remote backend, configure it here and give this example its own unique backend key. For example:

```hcl
backend "s3" {
  bucket       = "your-terraform-state-bucket"
  key          = "examples/ecr/terraform.tfstate"
  region       = "us-east-1"
  use_lockfile = true
  encrypt      = true
}
```

Do not store state inside `modules/ecr/`.

## Artifacts you should not commit

From this directory, do not commit:

- `.terraform/`
- `terraform.tfstate`
- `terraform.tfstate.backup`

The repository `.gitignore` is set up to exclude these. If you ever see them showing up as untracked files, that usually means the example was initialized without a clean workspace or the `.gitignore` is not being read where you expect.

A root configuration's lock file, `.terraform.lock.hcl`, is expected to be committed once this example is initialized for real.

## Troubleshooting

If validation fails, check that your lifecycle policy follows the correct structure. Lifecycle policies use a specific grammar with rules, selections, and actions.

If `terraform apply` fails with a repository name conflict, choose a unique `repository_name`. ECR repository names must be unique within your account and region.

If you get permission errors when pushing images, make sure your IAM user/role has `ecr:GetAuthorizationToken`, `ecr:BatchCheckLayerAvailability`, `ecr:GetDownloadUrlForLayer`, `ecr:BatchGetImage`, and `ecr:PutImage` permissions.

## Production example

For a production repository with immutability and KMS encryption:

```bash
terraform apply \
  -var="repository_name=production/web-api" \
  -var="image_tag_mutability=IMMUTABLE" \
  -var="encryption_type=aws:kms" \
  -var="kms_key_id=arn:aws:kms:us-east-1:123456789012:key/abc123"
```

## Notes

- ECR repository names must be unique within your AWS account and region.
- The default lifecycle policy keeps the last 10 images. Adjust based on your needs.
- `repository_url` is the URL you use for Docker operations. It includes your account ID and region.
- For ECS or EKS, reference images using the `repository_url` plus tag.
- Image scanning is free but review findings regularly.

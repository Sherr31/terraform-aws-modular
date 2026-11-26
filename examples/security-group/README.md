# Security Group Example

This is a working example of the reusable security group module.

It creates a security group for web servers with:

- HTTP (80) and HTTPS (443) ingress from the internet
- HTTPS and HTTP egress to the internet

## What this example is for

It shows how a root configuration calls `modules/security-group` and uses its outputs.

The module source path from this example is `../../modules/security-group`.

Security groups are **free** — there is no charge for creating or using them.

## Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform `>= 1.5`
- Credentials with permission to create security groups
- A VPC ID to pass in via `vpc_id` variable

## Commands

### 1) Formatting and validation, no AWS needed

```bash
cd examples/security-group

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

Read the plan before anything else. It should show one security group with ingress and egress rules.

You will need to provide a `vpc_id`:

```bash
terraform plan -var="vpc_id=vpc-12345678"
```

### 3) Apply with approval

```bash
terraform apply
```

Or with a specific VPC ID:

```bash
terraform apply -var="vpc_id=vpc-12345678"
```

Do not run this unless you want a real security group created.

### 4) Read outputs

```bash
terraform output
terraform output -raw security_group_id
```

### 5) Destroy when finished

```bash
terraform destroy
```

Security groups are free, but clean up when you are done.

## Cost warning

Security groups are **free**. No cost for creation or usage.

## Module inputs used

| Input | Value source |
|-------|--------------|
| `name` | `${var.name_prefix}-web-sg` |
| `description` | `Security group for web servers` |
| `vpc_id` | `var.vpc_id` (required) |
| `ingress_rules` | `var.ingress_rules` |
| `egress_rules` | `var.egress_rules` |
| `tags` | merged from `var.tags` and `Purpose = "web"` |

## Module outputs used

This example exposes:

- `security_group_id`
- `security_group_arn`

## Backend state

By default this example uses local state.

If you want a remote backend, configure it here and give this example its own unique backend key. For example:

```hcl
backend "s3" {
  bucket       = "your-terraform-state-bucket"
  key          = "examples/security-group/terraform.tfstate"
  region       = "us-east-1"
  use_lockfile = true
  encrypt      = true
}
```

Do not store state inside `modules/security-group/`.

## Artifacts you should not commit

From this directory, do not commit:

- `.terraform/`
- `terraform.tfstate`
- `terraform.tfstate.backup`

The repository `.gitignore` is set up to exclude these. If you ever see them showing up as untracked files, that usually means the example was initialized without a clean workspace or the `.gitignore` is not being read where you expect.

A root configuration's lock file, `.terraform.lock.hcl`, is expected to be committed once this example is initialized for real.

## Troubleshooting

If validation fails, check that your rule objects have the correct structure. Each rule needs `protocol`, `from_port`, `to_port`, and at least one of `cidr_blocks`, `security_groups`, `prefix_list_ids`, or `self`.

If `terraform plan` fails with a missing `vpc_id`, provide it:

```bash
terraform plan -var="vpc_id=vpc-12345678"
```

If security group creation fails with a name conflict, choose a different `name_prefix`.

## Notes

- The default ingress rules allow HTTP and HTTPS from anywhere. For production, consider restricting ingress to specific sources or load balancer security groups.
- The default egress rules allow HTTP and HTTPS outbound. Adjust based on what your application actually needs.
- To use this security group with an EC2 instance, pass the `security_group_id` output to the `vpc_security_group_ids` argument of the EC2 module.

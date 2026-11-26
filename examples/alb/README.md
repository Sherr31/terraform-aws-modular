# ALB Example

This is a working example of the reusable ALB module.

It creates:
- 1 Application Load Balancer (internet-facing by default)
- 1 security group (optional, created by default)
- 1 default target group with health checks
- 1 HTTP listener on port 80

## What this example is for

It shows how a root configuration calls `modules/alb` and uses its outputs.

The module source path from this example is `../../modules/alb`.

## Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform `>= 1.5`
- Credentials with permission to create ALBs, security groups, target groups, and listeners
- A VPC with at least 2 subnets in different AZs

## Commands

### 1) Formatting and validation, no AWS needed

```bash
cd examples/alb

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
terraform plan -var="vpc_id=vpc-12345678" -var="subnet_ids=[\"subnet-aaa\",\"subnet-bbb\"]"
```

Read the plan before anything else. It should show:
- 1 ALB
- 1 security group (if `create_security_group = true`)
- 1 target group
- 1 listener

### 3) Apply with approval

```bash
terraform apply -var="vpc_id=vpc-12345678" -var="subnet_ids=[\"subnet-aaa\",\"subnet-bbb\"]"
```

Do not run this unless you want a real ALB created.

**ALBs cost money** — approximately $16-20/month in us-east-1 at low traffic, plus data transfer.

### 4) Read outputs

```bash
terraform output
terraform output -raw alb_dns_name
terraform output -raw target_group_arn
```

### 5) Destroy when finished

```bash
terraform destroy -var="vpc_id=vpc-12345678" -var="subnet_ids=[\"subnet-aaa\",\"subnet-bbb\"]"
```

If deletion protection is enabled, you must disable it first or the destroy will fail.

## Cost warning

ALB pricing includes:

- **Hourly charge:** ~$0.0225/hour (~$16/month) in us-east-1
- **LCU charges:** based on connections, rules, and data processed
- **Data transfer:** standard AWS data transfer rates

**Always destroy ALBs when done with labs** to avoid ongoing charges.

## Module inputs used

| Input | Value source |
|-------|--------------|
| `name_prefix` | `var.name_prefix` |
| `subnet_ids` | `var.subnet_ids` (required) |
| `vpc_id` | `var.vpc_id` (required) |
| `internal` | `var.internal` |
| `create_security_group` | `var.create_security_group` |
| `security_group_id` | `var.security_group_id` |
| `alb_ingress_rules` | `var.alb_ingress_rules` |
| `alb_egress_rules` | `var.alb_egress_rules` |
| `listener_port` | `var.listener_port` |
| `listener_protocol` | `var.listener_protocol` |
| `target_group_port` | `var.target_group_port` |
| `target_group_protocol` | `var.target_group_protocol` |
| `target_type` | `var.target_type` |
| Health check settings | various `var.health_check_*` variables |
| `tags` | merged from `var.tags` and `Purpose = "alb"` |

## Module outputs used

This example exposes:

- `alb_arn`
- `alb_dns_name`
- `alb_zone_id`
- `target_group_arn`
- `security_group_id`

## Backend state

By default this example uses local state.

If you want a remote backend, configure it here and give this example its own unique backend key. For example:

```hcl
backend "s3" {
  bucket       = "your-terraform-state-bucket"
  key          = "examples/alb/terraform.tfstate"
  region       = "us-east-1"
  use_lockfile = true
  encrypt      = true
}
```

Do not store state inside `modules/alb/`.

## Artifacts you should not commit

From this directory, do not commit:

- `.terraform/`
- `terraform.tfstate`
- `terraform.tfstate.backup`

The repository `.gitignore` is set up to exclude these. If you ever see them showing up as untracked files, that usually means the example was initialized without a clean workspace or the `.gitignore` is not being read where you expect.

A root configuration's lock file, `.terraform.lock.hcl`, is expected to be committed once this example is initialized for real.

## Troubleshooting

If validation fails, check that you provided at least 2 subnet IDs in different AZs. ALBs require subnets in at least 2 AZs.

If `terraform plan` fails with a missing variable error, provide `vpc_id` and `subnet_ids`:

```bash
terraform plan -var="vpc_id=vpc-12345678" -var="subnet_ids=[\"subnet-aaa\",\"subnet-bbb\"]"
```

If the ALB fails to create, check that:
- The subnets are in different AZs
- The subnets have available IP addresses
- The security group rules are valid

If destroy fails with a deletion protection error, set `enable_deletion_protection = false` and apply once before destroying.

## Internal ALB example

To create an internal ALB instead of internet-facing:

```bash
terraform apply \
  -var="vpc_id=vpc-12345678" \
  -var="subnet_ids=[\"subnet-private-1\",\"subnet-private-2\"]" \
  -var="internal=true" \
  -var="alb_ingress_rules=[]"
```

Internal ALBs:
- Have no public IP address
- Are accessible only from within the VPC or connected networks
- Typically use private subnets

## Notes

- The ALB DNS name is stable but not user-friendly. Create a Route 53 record with the `alb_zone_id` to give it a friendly domain name.
- The default target group has no targets registered. Register targets separately or use Auto Scaling groups that automatically register with the target group.
- For HTTPS, you would add an SSL certificate and update the listener to use HTTPS.
- Security groups for ALBs should allow inbound traffic on the listener port from your expected sources.

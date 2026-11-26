# VPC Example

This is a working example of the reusable VPC module.

It creates a small lab VPC with:

- 1 VPC
- Public subnets
- Private subnets
- 1 Internet Gateway
- Optional NAT Gateway
- Public and private route tables

## What this example is for

It shows how a real root configuration calls `modules/vpc` and uses its outputs.

The module source path from this example is `../../modules/vpc`.

It is intentionally low cost by default:

- `enable_nat_gateway = false`
- No EC2 instances, ALB, or other charged resources are created by this example alone.

## Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform `>= 1.5`
- Credentials with permission to create VPC, subnet, gateway, route table, and EIP resources if NAT is enabled

## Commands

### 1) Formatting and validation, no AWS needed

```bash
cd examples/vpc

terraform fmt -check
terraform fmt
terraform init -backend=false
terraform validate
```

This is the first thing to run after changing the example or the module it calls.

- `terraform fmt -check` confirms formatting.
- `terraform fmt` fixes formatting if needed.
- `terraform init -backend=false` initializes providers and the module without requiring a remote backend.
- `terraform validate` confirms the configuration is structurally valid.

### 2) Plan only

```bash
terraform plan
```

Read the plan before anything else. It should show only the VPC, subnets, gateways, and route tables you asked for.

### 3) Apply with approval

```bash
terraform apply
```

Do not run this unless you want real AWS resources created.

### 4) Read outputs

```bash
terraform output
terraform output -raw vpc_id
```

### 5) Destroy when finished

```bash
terraform destroy
```

If you enabled NAT, destroy promptly to stop NAT Gateway and Elastic IP charges.

## Cost warning

If you set `enable_nat_gateway = true`, you will pay for:

- the NAT Gateway
- the associated Elastic IP
- data processing charges for traffic through the NAT

Destroy the example when you are finished learning.

## Module inputs used

| Input | Value source |
|-------|--------------|
| `name_prefix` | `var.name_prefix` |
| `cidr_block` | `var.vpc_cidr` |
| `az_count` | `var.az_count` |
| `public_subnet_cidrs` | `var.public_subnet_cidrs` |
| `private_subnet_cidrs` | `var.private_subnet_cidrs` |
| `enable_nat_gateway` | `var.enable_nat_gateway` |
| `tags` | `var.tags` |

## Module outputs used

This example exposes:

- `vpc_id`
- `public_subnet_ids`
- `private_subnet_ids`
- `azs`
- `internet_gateway_id`
- `public_route_table_id`
- `private_route_table_id`

The module also exports `nat_gateway_ids`, `public_subnet_cidrs`, and `private_subnet_cidrs` if you need them.

## Backend state

By default this example uses local state.

If you want a remote backend, configure it here and give this example its own unique backend key. For example:

```hcl
backend "s3" {
  bucket       = "your-terraform-state-bucket"
  key          = "examples/vpc/terraform.tfstate"
  region       = "us-east-1"
  use_lockfile = true
  encrypt      = true
}
```

Do not store state inside `modules/vpc/`.

## Artifacts you should not commit

From this directory, do not commit:

- `.terraform/`
- `terraform.tfstate`
- `terraform.tfstate.backup`

The repository `.gitignore` is set up to exclude these. If you ever see them showing up as untracked files, that usually means the example was initialized without a clean workspace or the `.gitignore` is not being read where you expect.

A root configuration's lock file, `.terraform.lock.hcl`, is expected to be committed once this example is initialized for real.

Right now, after `terraform init -backend=false`, the only new artifact this example creates that you would normally commit is `.terraform.lock.hcl`. Everything else should either already be tracked or already ignored.

If you are using this example only to test the module locally, you can keep its `.terraform.lock.hcl` in place. If you prefer a cleaner repo, delete it and `terraform init` again once the example is wired to a real backend.

# VPC Module

Reusable Terraform module that creates an isolated AWS VPC with public and private subnets, an Internet Gateway, optional NAT Gateway, and route tables.

## What it creates

- 1 VPC
- Public subnets, one per AZ
- Private subnets, one per AZ
- 1 Internet Gateway
- Optional NAT Gateway and Elastic IP
- Public and private route tables with associations

## Important inputs

- `name_prefix` — used in resource Name tags.
- `cidr_block` — VPC CIDR.
- `az_count` — number of AZs for subnets.
- `public_subnet_cidrs` — one CIDR per public subnet.
- `private_subnet_cidrs` — one CIDR per private subnet.
- `enable_nat_gateway` — create NAT/EIP for private subnet egress.
- `tags` — extra tags merged onto resources.

## NAT Gateway cost

NAT Gateway is optional and disabled by default.

If you enable it:

- you pay for the NAT Gateway,
- you pay for the associated Elastic IP,
- traffic through the NAT can also incur data processing charges.

Use `enable_nat_gateway = false` for low-cost labs unless private subnet internet access is required.

## Validation

The module requires:

- `az_count` between 1 and 3
- `public_subnet_cidrs` length equals `az_count`
- `private_subnet_cidrs` length equals `az_count`

## Outputs

- `vpc_id`
- `vpc_cidr_block`
- `public_subnet_ids`
- `private_subnet_ids`
- `azs`
- `nat_gateway_ids`
- `internet_gateway_id`
- `public_route_table_id`
- `private_route_table_id`
- `public_subnet_cidrs`
- `private_subnet_cidrs`

## Usage

This is a child module. Do not apply it directly. Call it from a root configuration.

Example:

```hcl
module "vpc" {
  source = "../../modules/vpc"

  name_prefix          = "lab"
  cidr_block           = "10.0.0.0/16"
  az_count             = 2
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  enable_nat_gateway   = false
}
```

## Notes

- DNS support and DNS hostnames are enabled by default.
- The NAT Gateway is placed in the first public subnet when enabled.
- Public subnets auto-assign public IPs on launch; private subnets do not.

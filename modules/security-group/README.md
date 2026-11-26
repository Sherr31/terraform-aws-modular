# Security Group Module

Reusable Terraform module that creates an AWS security group with configurable ingress and egress rules.

## What it creates

- 1 security group
- Optional ingress rules (one resource per rule)
- Optional egress rules (one resource per rule)

## Important inputs

| Input | Required | Default | Notes |
|-------|----------|---------|-------|
| `name` | yes | none | Security group name (unique in VPC) |
| `description` | no | `Managed by Terraform` | SG description |
| `vpc_id` | yes | none | VPC where the SG is created |
| `revoke_rules_on_delete` | no | `false` | Revoke rules before delete |
| `ingress_rules` | no | `[]` | List of ingress rules |
| `egress_rules` | no | `[]` | List of egress rules |
| `tags` | no | `{}` | Additional tags |

## Security group rules

Security groups act as virtual firewalls for AWS resources. They control:

- **Ingress** — traffic allowed INTO the resource
- **Egress** — traffic allowed OUT OF the resource

By default, AWS security groups:
- Allow **all outbound** traffic (if no egress rules are specified)
- Deny **all inbound** traffic (if no ingress rules are specified)

This module lets you define explicit rules for both directions.

## Rule structure

Each rule is an object with these fields:

| Field | Required | Description |
|-------|----------|-------------|
| `protocol` | yes | Protocol: `tcp`, `udp`, `icmp`, `-1` (all), or a protocol number |
| `from_port` | yes | Start of port range (use 0 for ICMP) |
| `to_port` | yes | End of port range (use 0 for ICMP) |
| `cidr_blocks` | no | IPv4 CIDR blocks to allow |
| `ipv6_cidr_blocks` | no | IPv6 CIDR blocks to allow |
| `prefix_list_ids` | no | Prefix list IDs (e.g. for S3 or DynamoDB access) |
| `security_groups` | no | Security group IDs to allow (reference-based rules) |
| `self` | no | If true, allow traffic from the same security group |
| `description` | no | Human-readable description of the rule |

**At least one of `cidr_blocks`, `ipv6_cidr_blocks`, `prefix_list_ids`, `security_groups`, or `self` must be specified.**

## Common examples

### SSH access from a specific IP

```hcl
ingress_rules = [
  {
    protocol      = "tcp"
    from_port     = 22
    to_port       = 22
    cidr_blocks   = ["203.0.113.0/24"]
    description   = "SSH from office IP range"
  }
]
```

### HTTP and HTTPS from the internet

```hcl
ingress_rules = [
  {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  },
  {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }
]
```

### Database access from application security group

```hcl
ingress_rules = [
  {
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    security_groups = [aws_security_group.app.id]
    description     = "PostgreSQL from app tier"
  }
]
```

### Allow all traffic within the same security group

```hcl
ingress_rules = [
  {
    protocol = "-1"
    from_port = 0
    to_port   = 0
    self      = true
    description = "Allow all internal traffic"
  }
]
```

### HTTPS egress only

```hcl
egress_rules = [
  {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound only"
  }
]
```

### Access to S3 via prefix list

```hcl
egress_rules = [
  {
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    prefix_list_ids = ["pl-12345678"]
    description     = "HTTPS to S3 only"
  }
]
```

## Security best practices

- **Least privilege:** Only open the ports and sources you need
- **Avoid `0.0.0.0/0` on sensitive ports:** SSH (22), RDP (3389), and database ports should be restricted
- **Use security group references:** Reference other security groups instead of CIDR blocks when possible — this is more maintainable
- **Add descriptions:** Describe why each rule exists for future maintainers
- **Review regularly:** Security group rules can accumulate over time

## Default security group behavior

This module creates a security group with **no rules by default** (both `ingress_rules` and `egress_rules` default to empty lists).

- Without ingress rules, all inbound traffic is denied
- Without egress rules, AWS allows all outbound traffic by default (this is AWS behavior, not module behavior)

If you want to be explicit about egress, define egress rules. If you want the default AWS behavior (allow all outbound), leave `egress_rules` empty.

## Outputs

- `security_group_id` — ID of the security group
- `security_group_arn` — ARN of the security group
- `security_group_name` — name of the security group
- `vpc_id` — VPC ID where the security group resides

## Usage

### Basic web server security group

```hcl
module "web_sg" {
  source = "../../modules/security-group"

  name        = "web-server-sg"
  description = "Security group for web servers"
  vpc_id      = var.vpc_id

  ingress_rules = [
    {
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP"
    },
    {
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS"
    },
    {
      protocol      = "tcp"
      from_port       = 22
      to_port         = 22
      cidr_blocks     = ["10.0.0.0/8"]
      description     = "SSH from VPC"
    }
  ]

  egress_rules = [
    {
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS outbound"
    }
  ]

  tags = {
    Project     = "web-app"
    Environment = "prod"
  }
}
```

### Internal-only security group

```hcl
module "internal_sg" {
  source = "../../modules/security-group"

  name        = "internal-app-sg"
  description = "Internal application security group"
  vpc_id      = var.vpc_id

  ingress_rules = [
    {
      protocol        = "tcp"
      from_port       = 8080
      to_port         = 8080
      security_groups = [aws_security_group.load_balancer.id]
      description     = "App traffic from load balancer"
    },
    {
      protocol = "-1"
      from_port = 0
      to_port   = 0
      self      = true
      description = "All internal traffic"
    }
  ]

  # No egress rules — relies on AWS default (allow all outbound)
  # Or set explicit egress rules for tighter control

  tags = {
    Project = "internal-app"
  }
}
```

## Cost notes

Security groups are **free**. There is no charge for creating or using security groups.

## Notes

- Security group rules are additive — AWS evaluates all rules across all security groups attached to a resource
- You can attach multiple security groups to an EC2 instance, ENI, or other resource
- Rule changes take effect immediately — no reboot needed
- Deleting a security group with existing rules will fail unless `revoke_rules_on_delete = true` or rules are removed first
- Security group names are unique within a VPC but not globally

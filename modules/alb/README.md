# ALB Module

Reusable Terraform module that creates an Application Load Balancer (ALB) with an optional security group, default target group, and HTTP listener.

## What it creates

- 1 Application Load Balancer (optional security group)
- 1 default target group with health checks
- 1 HTTP listener forwarding to the target group

## Important inputs

| Input | Required | Default | Notes |
|-------|----------|---------|-------|
| `subnet_ids` | yes | none | Subnets for the ALB |
| `vpc_id` | yes | none | VPC ID |
| `name_prefix` | no | `null` | Prefix for resource names |
| `internal` | no | `false` | Internal vs internet-facing ALB |
| `create_security_group` | no | `true` | Create ALB security group |
| `security_group_id` | no | `null` | Use existing SG instead |
| `alb_ingress_rules` | no | `[]` | Ingress rules for ALB SG |
| `alb_egress_rules` | no | allow all outbound | Egress rules for ALB SG |
| `ip_address_type` | no | `ipv4` | `ipv4` or `dualstack` |
| `enable_deletion_protection` | no | `false` | Protect from deletion |
| `listener_port` | no | `80` | Listener port |
| `listener_protocol` | no | `HTTP` | Listener protocol |
| `target_group_port` | no | `80` | Target group port |
| `target_group_protocol` | no | `HTTP` | Target group protocol |
| `target_type` | no | `instance` | `instance`, `ip`, or `lambda` |
| `health_check_*` | no | various | Health check settings |

## ALB types

### Internet-facing ALB

```hcl
module "alb" {
  source = "../../modules/alb"

  name_prefix = "web"
  internal    = false

  subnet_ids = ["subnet-public-1", "subnet-public-2"]
  vpc_id     = var.vpc_id

  alb_ingress_rules = [
    {
      description = "HTTP from internet"
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
```

### Internal ALB

```hcl
module "internal_alb" {
  source = "../../modules/alb"

  name_prefix = "internal-api"
  internal    = true

  subnet_ids = ["subnet-private-1", "subnet-private-2"]
  vpc_id     = var.vpc_id

  alb_ingress_rules = [
    {
      description = "HTTPS from VPC"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_blocks = ["10.0.0.0/8"]
    }
  ]
}
```

## Security groups

The module can create a security group for the ALB automatically, or you can provide an existing one.

### Let the module create one

```hcl
create_security_group = true
alb_ingress_rules = [
  {
    description = "HTTP from internet"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
]
```

### Use an existing security group

```hcl
create_security_group = false
security_group_id     = aws_security_group.alb.id
```

When `security_group_id` is provided, it takes precedence over `create_security_group`.

## Target groups

The module creates a default target group. You can register targets with it separately, or use the output `target_group_arn` to attach it to other resources.

### Target types

- **instance** (default) — register EC2 instances by instance ID
- **ip** — register targets by IP address (useful for containers, on-premises)
- **lambda** — register a Lambda function as a target

## Health checks

The module configures a health check with sensible defaults:

| Setting | Default | Description |
|---------|---------|-------------|
| `health_check_enabled` | `true` | Enable health checks |
| `health_check_protocol` | `HTTP` | Protocol for health checks |
| `health_check_path` | `/` | Path to check |
| `health_check_port` | `traffic-port` | Port to check |
| `health_check_interval` | `30` | Seconds between checks |
| `health_check_timeout` | `5` | Seconds to wait for response |
| `health_healthy_threshold` | `3` | Successes before healthy |
| `health_unhealthy_threshold` | `3` | Failures before unhealthy |
| `health_check_matcher` | `200` | Expected response code |

For a REST API, you might use:

```hcl
health_check_path    = "/health"
health_check_matcher = "200-299"
```

## Listeners

The module creates a default HTTP listener on port 80. For HTTPS, you would typically:

1. Set `listener_protocol = "HTTPS"`
2. Provide an SSL certificate ARN (via a separate `aws_lb_listener_certificate` resource or by extending the module)

## Deletion protection

`enable_deletion_protection` prevents accidental deletion of the ALB. Set it to `true` in production environments.

When enabled, you must disable it before Terraform can destroy the ALB.

## Outputs

- `alb_arn` — ARN of the ALB
- `alb_dns_name` — DNS name of the ALB
- `alb_zone_id` — Route 53 zone ID for ALIAS records
- `alb_id` — ID of the ALB
- `security_group_id` — security group ID used by the ALB
- `target_group_arn` — ARN of the default target group
- `target_group_name` — name of the default target group
- `listener_arn` — ARN of the default listener

## Usage with EC2 and security groups

A typical setup: VPC → security group → EC2 → ALB → target group

```hcl
module "vpc" {
  source = "../../modules/vpc"
  # ... VPC configuration
}

module "alb_sg" {
  source = "../../modules/security-group"

  name        = "alb-sg"
  description = "ALB security group"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description = "HTTP from internet"
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "app_sg" {
  source = "../../modules/security-group"

  name        = "app-sg"
  description = "Application security group"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description     = "HTTP from ALB"
      protocol        = "tcp"
      from_port       = 80
      to_port         = 80
      security_groups = [module.alb_sg.security_group_id]
    }
  ]
}

module "alb" {
  source = "../../modules/alb"

  name_prefix = "web"
  subnet_ids  = module.vpc.public_subnet_ids
  vpc_id      = module.vpc.vpc_id

  security_group_id = module.alb_sg.security_group_id
  create_security_group = false
}

module "ec2" {
  source = "../../modules/ec2"

  # ... EC2 configuration
  subnet_id           = module.vpc.private_subnet_ids[0]
  security_group_ids  = [module.app_sg.security_group_id]
}
```

## Cost notes

ALB pricing includes:

- **Load balancer capacity:** hourly charge (~$0.0225/hour for ALB in us-east-1)
- **LCU (Load Balancer Capacity Units):** based on new connections, active connections, rule evaluations, and data processed
- **Data transfer:** standard AWS data transfer rates

An internet-facing ALB in us-east-1 costs approximately $16-20/month at low traffic, plus data transfer costs.

**Always destroy ALBs when done with labs** to avoid ongoing charges.

## Notes

- ALBs must be placed in at least 2 subnets in different AZs
- Internet-facing ALBs need public subnets; internal ALBs can use private subnets
- The ALB security group should allow inbound traffic on the listener port from the sources you expect
- Application security groups should allow inbound traffic from the ALB security group, not from the internet directly
- `alb_zone_id` is useful for creating Route 53 ALIAS records that point to the ALB
- Deletion protection must be disabled before destroying the ALB

# Infrastructure Lab — Integrated AWS Application

A complete, cost-conscious AWS application that combines multiple reusable modules into a working architecture.

## Architecture

```
Internet
   │
   ▼
┌─────────────────────────────────────────┐
│           Public ALB (port 80)          │
│   alb-xxxxx.elb.us-east-1.amazonaws.com │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│        Private Subnets (10.0.11.0/24    │
│                          10.0.12.0/24)  │
│   ┌─────────────────────────────────┐   │
│   │  Auto Scaling Group             │   │
│   │  ┌─────────┐ ┌─────────┐       │   │
│   │  │ EC2 t3.m │ │ EC2 t3.m │       │   │
│   │  │ micro   │ │ micro   │       │   │
│   │  │ :8080   │ │ :8080   │       │   │
│   │  └─────────┘ └─────────┘       │   │
│   └─────────────────────────────────┘   │
└────────────────┬────────────────────────┘
                 │
                 ▼
        [No NAT Gateway]
        [No internet access from instances]
```

### What gets created

| Resource | Module | Count | Notes |
|----------|--------|-------|-------|
| VPC | `modules/vpc` | 1 | 10.0.0.0/16, 2 AZs |
| Public subnets | `modules/vpc` | 2 | One per AZ, routes to IGW |
| Private subnets | `modules/vpc` | 2 | One per AZ, no internet route |
| Internet Gateway | `modules/vpc` | 1 | Attached to VPC |
| ALB | `modules/alb` | 1 | Internet-facing, port 80 |
| ALB Security Group | `modules/alb` | 1 | Allows 0.0.0.0/0:80 |
| App Security Group | `modules/security-group` | 1 | Allows ALB SG:8080 only |
| Launch Template | `modules/autoscaling` | 1 | Defines instance configuration |
| Auto Scaling Group | `modules/autoscaling` | 1 | Min 1, max 2 instances |
| EC2 Instances | `modules/autoscaling` | 1-2 | t3.micro, private, no public IP |

### Traffic flow

1. User requests `http://alb-xxxxx.elb.us-east-1.amazonaws.com`
2. ALB receives the request on port 80 (public subnet)
3. ALB forwards to a target (EC2 instance) on port 8080 (private subnet)
4. EC2 instance runs a Python HTTP server that responds to `/health`
5. ALB health check polls `/health` every 30 seconds — if 200, instance is healthy

### Security controls

| Control | Implementation |
|---------|---------------|
| Instances are private | No public IP, in private subnets |
| Internet cannot reach instances directly | App SG only allows ALB SG |
| ALB is internet-facing but limited | Only port 80 open from 0.0.0.0/0 |
| IMDSv2 required | Instances require session tokens for metadata |
| Root volume encrypted | EBS encryption enabled by default |
| No SSH from internet | No SSH rules in any security group |

### Why no NAT Gateway

A NAT Gateway would allow instances in private subnets to reach the internet (for `apt`/`yum` updates, calling external APIs, etc.). It costs:

- **~$0.045/hour** (~$33/month)
- **~$0.045/GB** data processing
- **Elastic IP** (free if attached, but still allocated)

For this lab, the instances don't need internet access. They run a simple Python server that doesn't pull packages or call external services. Removing the NAT Gateway saves ~$33/month.

If you need internet access later, set `enable_nat_gateway = true` in the VPC module and remove `associate_public_ip = false` from the ASG if you want instances to use the NAT.

## Requirements

- Terraform >= 1.5
- AWS provider >= 5.0, < 6.0
- A valid AMI ID for your region (see `variables.tf` for how to find one)
- AWS credentials configured (`aws configure` or environment variables)

## Quick Start

### 1) Find an AMI ID

```bash
# Amazon Linux 2023 (recommended)
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-2023.*-x86_64" \
  --query "Images[0].ImageId" \
  --region us-east-1
```

Copy the AMI ID (e.g., `ami-0abc123def456789`).

### 2) Validate (no AWS needed)

```bash
cd apps/infrastructure-lab

terraform fmt -check
terraform init -backend=false
terraform validate
```

### 3) Plan

```bash
terraform plan -var="ami=ami-0abc123def456789"
```

Review the plan carefully. It should show:
- 1 VPC, 4 subnets, 1 IGW
- 1 ALB, 2 security groups, 1 target group
- 1 launch template, 1 ASG

### 4) Apply (requires AWS)

```bash
terraform apply -var="ami=ami-0abc123def456789"
```

After apply, the `alb_dns_name` output gives you the URL to access the application:

```bash
terraform output -raw alb_dns_name
```

Then in another terminal:

```bash
curl http://alb-xxxxx.elb.us-east-1.amazonaws.com/health
```

Expected response:

```json
{
  "status": "healthy",
  "instance_id": "i-0abc123def456789",
  "hostname": "ip-10-0-11-15.us-east-1.compute.internal",
  "region": "us-east-1"
}
```

### 5) Destroy when done

```bash
terraform destroy -var="ami=ami-0abc123def456789"
```

**Important:** Confirm the destroy plan before approving. It will delete all resources created by this application.

## Variables

### Required

| Variable | Description |
|----------|-------------|
| `ami` | AMI ID for EC2 instances. Must be valid in your region. |

### Optional

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | AWS region |
| `name_prefix` | `infra-lab` | Prefix for resource names |
| `environment` | `dev` | Environment label |
| `vpc_cidr_block` | `10.0.0.0/16` | VPC CIDR |
| `az_count` | `2` | Number of AZs (1-3) |
| `public_subnet_cidrs` | `["10.0.1.0/24", "10.0.2.0/24"]` | Public subnet CIDRs |
| `private_subnet_cidrs` | `["10.0.11.0/24", "10.0.12.0/24"]` | Private subnet CIDRs |
| `instance_type` | `t3.micro` | EC2 instance type |
| `asg_min_size` | `1` | Minimum ASG instances |
| `asg_max_size` | `2` | Maximum ASG instances |
| `asg_desired_capacity` | `1` | Desired ASG capacity |
| `alb_listener_port` | `80` | ALB listener port |
| `app_port` | `8080` | Application port on instances |
| `tags` | `{}` | Additional tags |

## Cost estimate

Approximate monthly cost for a minimal deployment in us-east-1:

| Resource | Calculation | Monthly cost |
|----------|-------------|--------------|
| ALB | $0.0225/hour | ~$16.20 |
| EC2 t3.micro | $0.0104/hour × 1 instance × 730 hours | ~$7.59 (free tier eligible) |
| EBS gp3 8GB | $0.08/GB-month × 8GB × 1 instance | ~$0.64 |
| **Total** | | **~$24.43/month** (or ~$7.59 with free tier) |

**Without free tier:** ~$24/month for a running application.

**With free tier (first 12 months):** ~$7.59/month (EC2 t3.micro is free tier eligible, 750 hours/month).

**If you scale to 2 instances:** Add ~$7.59/month per additional instance.

**If you enable a NAT Gateway:** Add ~$33/month + data processing charges.

## How the modules connect

```
modules/vpc
  ├─▶ vpc_id ──────────────┐
  ├─▶ public_subnet_ids ────┼──▶ modules/alb (subnet_ids)
  └─▶ private_subnet_ids ───┼──▶ modules/autoscaling (subnet_ids)
                             │
modules/alb                 │
  ├─▶ security_group_id ────┼──▶ modules/security-group (ingress: security_groups)
  ├─▶ target_group_arn ─────┼──▶ modules/autoscaling (target_group_arns)
  └─▶ alb_dns_name ─────────┼──▶ output

modules/security-group
  └─▶ security_group_id ────┼──▶ modules/autoscaling (security_group_ids)
```

The key connection: the ALB module's security group ID is passed to the app security group as an allowed source. This means only the ALB can reach the instances.

## Troubleshooting

### Instances show as unhealthy

1. Check the ALB target group health in the AWS console
2. Verify the user data script ran: connection to the instance (if possible) and check `/var/log/app-server.log`
3. Confirm the app is listening on port 8080: the user data starts `python3 /app/server.py` on port 8080 by default
4. Check security groups: the app SG must allow the ALB SG on port 8080

### ALB DNS name doesn't resolve

ALB DNS names can take a minute or two to propagate after creation. Wait 60 seconds and try again.

### `terraform validate` fails with module errors

Make sure you've run `terraform init` first. The modules are referenced with relative paths (`../../modules/vpc`) and must be resolved by Terraform.

### `terraform apply` fails with AMI not found

The AMI ID must be valid in your selected region. Run the AMI lookup command in the Quick Start for your region.

### Instances don't have internet access

This is expected. The architecture has no NAT Gateway. Instances in private subnets with no public IP cannot reach the internet. This is a cost-saving design choice. If you need internet access, enable the NAT Gateway in the VPC module.

## Destroying

```bash
terraform destroy -var="ami=ami-0abc123def456789"
```

Type `yes` to confirm. All resources created by this application will be deleted.

**Warning:** This destroys the VPC, subnets, ALB, security groups, launch template, ASG, and all EC2 instances. Make sure you don't need any of these resources before destroying.

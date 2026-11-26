# Auto Scaling Module

Reusable Terraform module that creates an Auto Scaling group with a launch template, optional IAM instance profile, and basic configuration for EC2 instances.

## What it creates

- 1 Launch Template (defines instance configuration)
- 1 Auto Scaling Group (manages the fleet)
- Optional: 1 IAM Instance Profile (for attaching an IAM role)

## Important inputs

| Input | Required | Default | Notes |
|-------|----------|---------|-------|
| `subnet_ids` | yes | none | Subnets for instances |
| `ami` | yes | none | AMI ID |
| `name_prefix` | no | `null` | Prefix for resource names |
| `instance_type` | no | `t3.micro` | Instance type |
| `security_group_ids` | no | `[]` | Security groups |
| `min_size` | no | `1` | Minimum instances |
| `max_size` | no | `3` | Maximum instances |
| `desired_capacity` | no | `1` | Desired instances |
| `health_check_type` | no | `EC2` | `EC2` or `ELB` |
| `target_group_arns` | no | `[]` | ALB target groups |
| `root_volume_size` | no | `10` | GiB |
| `root_volume_encrypted` | no | `true` | Encryption |
| `imdsv2_required` | no | `true` | IMDSv2 |
| `user_data` | no | `null` | Startup script |
| `key_name` | no | `null` | Key pair |
| `create_iam_instance_profile` | no | `false` | Create profile |
| `iam_role_name` | no | `null` | IAM role name |

## Basic usage

```hcl
module "asg" {
  source = "../../modules/autoscaling"

  name_prefix    = "web"
  ami            = data.aws_ami.amazon_linux.id
  instance_type  = "t3.micro"
  subnet_ids     = module.vpc.private_subnet_ids
  min_size       = 1
  max_size       = 3
  desired_capacity = 2

  health_check_type   = "ELB"
  health_check_grace_period = 300

  target_group_arns = [module.alb.target_group_arn]

  security_group_ids = [module.app_sg.security_group_id]

  tags = {
    Project     = "web-app"
    Environment = "prod"
  }
}
```

## Launch template

The launch template defines how instances are launched. It includes:

- AMI and instance type
- Network settings (subnet, security groups, public IP)
- Storage configuration (root volume)
- IAM instance profile
- Metadata options (IMDSv2)
- User data for bootstrapping
- Key pair for SSH access
- Monitoring configuration

### Root volume

By default, instances get an encrypted gp3 root volume of 10 GiB that is deleted on termination.

```hcl
root_volume_size      = 20
root_volume_type      = "gp3"
root_volume_encrypted = true
root_delete_on_termination = true
```

For provisioned IOPS volumes:

```hcl
root_volume_type = "io2"
root_volume_iops = 3000
```

### User data

User data runs on first boot. Pass it as a string:

```hcl
user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y nginx
              systemctl start nginx
              EOF
```

### IMDSv2

IMDSv2 is required by default for security. This prevents token-based attacks against the instance metadata service.

```hcl
imdsv2_required = true
http_put_response_hop_limit = 1
```

## Auto Scaling Group

The ASG manages the fleet of instances. Key settings:

### Sizing

```hcl
min_size         = 1
max_size         = 5
desired_capacity = 2
```

The ASG maintains between min and max instances, aiming for desired_capacity.

### Health checks

```hcl
health_check_type   = "ELB"  # Use ALB health checks
health_check_grace_period = 300  # 5 minutes after launch
```

- **EC2** — checks instance status
- **ELB** — uses target group health checks (recommended for ALB-backed ASGs)

### Target groups

Attach the ASG to an ALB target group:

```hcl
target_group_arns = [module.alb.target_group_arn]
```

Instances are automatically registered with the target group.

### Instance refresh

When you update the launch template, the ASG rolls out new instances gradually:

```hcl
instance_refresh_strategy = "Rolling"
instance_refresh_min_healthy_percentage = 50
instance_refresh_auto_rollback = true
```

### Termination policies

```hcl
termination_policies = ["Default", "OldestInstance", "NewestInstance"]
```

Common policies:
- **Default** — AWS chooses based on internal criteria
- **OldestInstance** — terminate oldest instances first
- **NewestInstance** — terminate newest instances first
- **OldestLaunchTemplate** — terminate instances with oldest launch template

## IAM instance profile

Attach an IAM role to instances for AWS API access:

```hcl
# First, create the role
module "app_role" {
  source = "../../modules/iam"
  role_name              = "asg-app-role"
  create_iam_instance_profile = true
  iam_role_name          = "app-role"
  # ... assume role policy and permissions
}

# Then use it in the ASG
module "asg" {
  source = "../../modules/autoscaling"

  name_prefix                 = "web"
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_ids                  = module.vpc.private_subnet_ids
  create_iam_instance_profile = true
  iam_role_name               = module.app_role.role_name

  tags = var.tags
}
```

Or use an existing instance profile:

```hcl
create_iam_instance_profile = false
iam_instance_profile_arn    = "arn:aws:iam::123456789012:instance-profile/my-profile"
```

## Scaling policies

This module does not create scaling policies by default. Add them in the root configuration:

```hcl
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "web-scale-up"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = module.asg.asg_name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "web-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = module.asg.asg_name
}
```

For target tracking scaling:

```hcl
resource "aws_autoscaling_target_tracking_configuration" "cpu" {
  autoscaling_group_name = module.asg.asg_name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
```

## Spot instances

For cost savings, you can use Spot instances by modifying the launch template:

```hcl
resource "aws_launch_template" "this" {
  # ... other settings

  instance_market_options {
    market_type = "spot"
    spot_options {
      instance_interruption_behavior = "terminate"
    }
  }
}
```

## Cost notes

Auto Scaling itself is free. You pay for:

- **EC2 instances** — hourly rate for running instances
- **Spot instances** — cheaper, but can be interrupted
- **EBS volumes** — per-GiB-month
- **Data transfer** — standard rates
- **Load balancer** — if attached (see ALB module cost notes)

Right-sizing and using Spot instances can significantly reduce costs.

## Outputs

- `asg_name` — name of the ASG
- `asg_arn` — ARN of the ASG
- `launch_template_id` — ID of the launch template
- `launch_template_arn` — ARN of the launch template
- `iam_instance_profile_name` — name of the instance profile (if created)

## Notes

- The ASG distributes instances across the provided subnets
- Instances are registered with target groups automatically
- When the launch template changes, an instance refresh rolls out new instances
- `ignore_changes = [desired_capacity]` prevents Terraform from overriding manual scaling
- Health check grace period should be long enough for instances to bootstrap
- ELB health checks require a target group attached to an ALB or NLB

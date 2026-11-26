# Auto Scaling Example

This is a working example of the reusable Auto Scaling module.

It creates:
- 1 Launch Template
- 1 Auto Scaling Group
- Optional: user data, key pair, monitoring

## What this example is for

It shows how a root configuration calls `modules/autoscaling` and uses its outputs.

The module source path from this example is `../../modules/autoscaling`.

Auto Scaling itself is free — you pay for the EC2 instances and other resources the ASG launches.

## Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform `>= 1.5`
- Credentials with permission to create launch templates, ASGs, and IAM instance profiles
- A VPC with subnets to pass in via `subnet_ids`
- An AMI ID valid for your region

## Commands

### 1) Formatting and validation, no AWS needed

```bash
cd examples/autoscaling

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
terraform plan -var="subnet_ids=[\"subnet-aaa\",\"subnet-bbb\"]"
```

Read the plan before anything else. It should show:
- 1 launch template
- 1 auto scaling group

### 3) Apply with approval

```bash
terraform apply -var="subnet_ids=[\"subnet-aaa\",\"subnet-bbb\"]"
```

Do not run this unless you want real EC2 instances and an ASG created.

### 4) Read outputs

```bash
terraform output
terraform output -raw asg_name
terraform output -raw launch_template_id
```

### 5) Destroy when finished

```bash
terraform destroy -var="subnet_ids=[\"subnet-aaa\",\"subnet-bbb\"]"
```

If instances are still running, destroy will terminate them.

## Cost warning

Auto Scaling is free, but you pay for:

- **EC2 instances** — hourly rate (t3.micro is ~$0.0104/hour in us-east-1)
- **EBS volumes** — per-GiB-month
- **Data transfer** — standard rates
- **Load balancer** — if attached (see ALB module)

A 1-instance ASG with t3.micro costs approximately $7-10/month at low usage.

**Always destroy ASGs when done with labs** to stop instance charges.

## Module inputs used

| Input | Value source |
|-------|--------------|
| `name_prefix` | `var.name_prefix` |
| `ami` | `var.ami` |
| `instance_type` | `var.instance_type` |
| `subnet_ids` | `var.subnet_ids` (required) |
| `security_group_ids` | `var.security_group_ids` |
| `min_size` | `var.min_size` |
| `max_size` | `var.max_size` |
| `desired_capacity` | `var.desired_capacity` |
| `health_check_type` | `var.health_check_type` |
| `health_check_grace_period` | `var.health_check_grace_period` |
| `target_group_arns` | `var.target_group_arns` |
| `root_volume_size` | `var.root_volume_size` |
| `root_volume_type` | `var.root_volume_type` |
| `root_volume_encrypted` | `var.root_volume_encrypted` |
| `imdsv2_required` | `var.imdsv2_required` |
| `enhanced_monitoring` | `var.enhanced_monitoring` |
| `user_data` | `var.user_data` |
| `key_name` | `var.key_name` |
| `termination_policies` | `var.termination_policies` |
| `tags` | merged from `var.tags` and `Purpose = "asg"` |

## Module outputs used

This example exposes:

- `asg_name`
- `asg_arn`
- `launch_template_id`

## Backend state

By default this example uses local state.

If you want a remote backend, configure it here and give this example its own unique backend key. For example:

```hcl
backend "s3" {
  bucket       = "your-terraform-state-bucket"
  key          = "examples/autoscaling/terraform.tfstate"
  region       = "us-east-1"
  use_lockfile = true
  encrypt      = true
}
```

Do not store state inside `modules/autoscaling/`.

## Artifacts you should not commit

From this directory, do not commit:

- `.terraform/`
- `terraform.tfstate`
- `terraform.tfstate.backup`

The repository `.gitignore` is set up to exclude these. If you ever see them showing up as untracked files, that usually means the example was initialized without a clean workspace or the `.gitignore` is not being read where you expect.

A root configuration's lock file, `.terraform.lock.hcl`, is expected to be committed once this example is initialized for real.

## Troubleshooting

If validation fails, check that you provided `subnet_ids`. The ASG requires at least one subnet.

If `terraform plan` shows errors about the AMI, make sure the AMI ID is valid for your region. AMI IDs are region-specific.

If instances fail to launch, check:
- Security group rules allow required traffic
- The AMI is available in your region
- Subnets have available IP addresses
- IAM role (if used) has proper permissions

If the ASG doesn't register with the target group, check:
- `health_check_type` is set to "ELB"
- `target_group_arns` includes the target group
- Instances can reach the ALB

## Notes

- The default AMI is a placeholder. Replace it with a region-appropriate AMI.
- User data runs only on first boot, not on every instance launch.
- The ASG spreads instances across the provided subnets automatically.
- When the launch template changes, an instance refresh replaces instances gradually.
- `ignore_changes = [desired_capacity]` in the ASG lifecycle means Terraform won't overwrite manual scaling adjustments.

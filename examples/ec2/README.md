# EC2 Example

This is a working example of the reusable EC2 module.

It creates:

- 1 EC2 instance
- 1 security group for the example
- 1 root EBS volume for the instance

It does not create a VPC in this example alone. The VPC is expected to exist
already, or to be created by another example and passed in through variables.

The module source path from this example is `../../modules/ec2`.

## What this example is for

It shows how a root configuration:

- configures the AWS provider,
- resolves inputs for an EC2 instance,
- attaches a subnet and security group,
- consumes module outputs,
- keeps public exposure off by default.

## Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform `>= 1.5`
- Credentials with permission to create EC2 instances, security groups, and,
  if you enable a public IP, Elastic IP behavior as applicable

## Inputs you must provide

This example has a few required inputs because a reusable EC2 module should not
guess your network layout:

- `subnet_id`
- `vpc_id`

Everything else has a default, including a placeholder AMI.

## Commands

### 1) Formatting and validation, no AWS needed

```bash
cd examples/ec2

terraform fmt -check
terraform fmt
terraform init -backend=false
terraform validate
```

- `terraform fmt -check` confirms formatting.
- `terraform fmt` fixes formatting if needed.
- `terraform init -backend=false` initializes providers and the module without
  requiring a remote backend.
- `terraform validate` confirms the configuration is structurally valid.

### 2) Plan only

```bash
terraform plan
```

Read the plan carefully. It should show:

- 1 EC2 instance
- 1 security group
- 1 root EBS volume

If `associate_public_ip = false`, the plan should not show a public IP being
requested.

### 3) Apply with approval

```bash
terraform apply
```

Do not run this unless you want real AWS resources created.

### 4) Read outputs

```bash
terraform output
terraform output -raw instance_id
terraform output -raw private_ip
```

If you enabled a public IP, you can also read:

```bash
terraform output -raw public_ip
terraform output -raw public_dns
```

### 5) Destroy when finished

```bash
terraform destroy
```

If you launched an instance with a public IP or key pair, destroy promptly when
you are done learning.

## Cost warning

This example is low cost for small instances and small volumes, but it is not
free.

Default costs you may see:

- instance running time,
- root EBS volume usage,
- any public IP or internet-bound traffic if you enable it,
- possible data transfer charges.

If you set `associate_public_ip = true`, make sure the security group and subnet
support the access you expect.

## Module inputs used

| Input | Value source |
|-------|--------------|
| `ami` | `var.ami` |
| `instance_type` | `var.instance_type` |
| `name` | `${var.name_prefix}-instance` |
| `subnet_id` | `var.subnet_id` |
| `security_group_ids` | `var.security_group_ids` |
| `associate_public_ip` | `var.associate_public_ip` |
| `key_name` | `var.key_name` |
| `user_data` | `var.user_data` |
| `imdsv2_required` | `var.imdsv2_required` |
| `root_block_device` | constructed in `main.tf` from `var.root_volume_size` |
| `tags` | `var.tags` |

## Example security group

This example creates a small security group for demonstration:

- SSH ingress from `var.ssh_cidr_blocks`
- all-traffic egress

In a real project, the security group would usually come from a dedicated
security group module or from another root configuration output.

## Backend state

By default this example uses local state.

If you want a remote backend, configure it here and give this example its own
unique backend key. For example:

```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "examples/ec2/terraform.tfstate"
  region         = "us-east-1"
  use_lockfile   = true
  encrypt        = true
}
```

Do not store state inside `modules/ec2/`.

## Artifacts you should not commit

From this directory, do not commit:

- `.terraform/`
- `terraform.tfstate`
- `terraform.tfstate.backup`

The repository `.gitignore` is set up to exclude these.

A root configuration's lock file, `.terraform.lock.hcl`, is expected to be
committed once this example is initialized for real.

## Troubleshooting

If validation fails with a missing required variable, check that you provided
`subnet_id` and `vpc_id`.

If `terraform init` cannot find the module, confirm the source path is
`../../modules/ec2` from this directory.

If you see AMI-related errors, remember this example uses a placeholder AMI
value. Replace it with the AMI you want for your region.

## Notes

- Public IP assignment is disabled by default.
- IMDSv2 is required by default.
- Root volume encryption is enabled by default.
- The example does not create or manage SSH keys. If you use `key_name`, the
  key pair must already exist in the account and region.

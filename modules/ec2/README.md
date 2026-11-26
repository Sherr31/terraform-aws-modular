# EC2 Module

Reusable Terraform module that creates a single EC2 instance with secure defaults.

## What it creates

- 1 EC2 instance
- 1 root EBS volume
- Optional key pair attachment
- Optional user data execution on first boot

## Important inputs

| Input | Required | Default | Notes |
|-------|----------|---------|-------|
| `ami` | yes | none | AMI ID. Should be resolved by the caller when region-awareness matters. |
| `instance_type` | no | `t3.micro` | Instance type. |
| `name` | yes | none | Name tag for the instance. |
| `tags` | no | `{}` | Additional tags. |
| `subnet_id` | yes | none | Subnet where the instance is launched. |
| `security_group_ids` | no | `[]` | Security group IDs to attach. |
| `associate_public_ip` | no | `false` | Whether to request a public IP. |
| `key_name` | no | `null` | Existing key pair name. |
| `user_data` | no | `null` | Startup script. |
| `imdsv2_required` | no | `true` | Default `true`. Require IMDSv2 tokens when true. |
| `root_block_device` | no | encrypted gp3 10 GiB | Root volume configuration. |

## Security and cost defaults

- Root volume encryption is enabled by default.
- IMDSv2 is required by default.
- Public IP assignment is disabled by default.
- The module does not create security groups, key pairs, subnets, or AMIs. It consumes them from the caller.

These defaults make the instance safer and cheaper for common lab and application use.

## AMI selection

The module does not resolve AMIs itself.

That is intentional. AMI IDs differ by region and by image build, and a reusable module should not hide that from the caller.

A common pattern is to resolve the AMI in the root configuration and pass it in:

```hcl
data "aws_ami" "amazon_linux" {
  most Recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"] # adjust to the image you want
  }
}

module "ec2_example" {
  source = "../../modules/ec2"

  ami             = data.aws_ami.amazon_linux.id
  name            = "example-instance"
  subnet_id       = module.vpc.private_subnet_ids[0]
  associate_public_ip = false
}
```

## Public vs private instances

If the instance only needs private connectivity, set:

- `associate_public_ip = false`
- a security group that allows only the traffic you need
- placement in a private subnet

If you need SSH or HTTPS from the internet, place the instance in a public subnet and open only the ports you need in its security group. Do not rely on a public IP alone to secure the instance.

## Outputs

- `instance_id`
- `arn`
- `public_ip`
- `private_ip`
- `public_dns`
- `availability_zone`
- `primary_network_interface_id`

## Usage

This is a child module. Do not apply it directly. Call it from a root configuration.

```hcl
module "ec2" {
  source = "../../modules/ec2"

  ami             = var.ami
  instance_type   = "t3.micro"
  name            = "example"
  subnet_id       = var.subnet_id
  security_group_ids = [var.security_group_id]
  associate_public_ip = false
  key_name        = var.key_name
}
```

## Notes

- The instance Name tag is set from `var.name`, merged with any extra tags you pass.
- User data is optional and only runs on first boot unless the instance is configured otherwise.
- The module does not manage SSH keys, AMIs, VPCs, or networking. Those belong to the root configuration or other modules.

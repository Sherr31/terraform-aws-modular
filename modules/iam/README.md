# IAM Module

Reusable Terraform module that creates an IAM role, an optional IAM policy, and an optional IAM instance profile.

## What it creates

- 1 IAM role (required)
- 1 IAM policy (optional, attached to the role)
- 1 IAM instance profile (optional, for EC2)

## Important inputs

| Input | Required | Default | Notes |
|-------|----------|---------|-------|
| `role_name` | yes | none | Name of the IAM role |
| `assume_role_policy` | yes | none | JSON policy for who can assume the role |
| `create_policy` | no | `true` | Whether to create and attach a policy |
| `policy_document` | no | basic S3 access | JSON policy document for permissions |
| `policy_name` | no | `role_name-policy` | Custom policy name |
| `policy_description` | no | auto-generated | Policy description |
| `policy_path` | no | `/` | Policy path |
| `create_instance_profile` | no | `false` | Whether to create an instance profile |
| `instance_profile_name` | no | `role_name-profile` | Custom instance profile name |
| `instance_profile_path` | no | `/` | Instance profile path |
| `max_session_duration` | no | `3600` | Max session duration in seconds (3600–43200) |
| `tags` | no | `{}` | Additional tags |

## IAM role

The IAM role is the core resource. It defines:

- **Who can assume it** (via `assume_role_policy`)
- **How long sessions can last** (via `max_session_duration`)
- **Tags** for organization and cost tracking

Example assume role policy for EC2:

```hcl
assume_role_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }
  ]
})
```

Example assume role policy for cross-account access:

```hcl
assume_role_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::123456789012:root"
      }
    }
  ]
})
```

## IAM policy

The policy defines what the role can do. By default, the module creates a basic policy that allows S3 read/write access to all resources — this is a placeholder you should replace with least-privilege permissions.

**Security best practice:** Always scope permissions to the minimum required. Avoid `Action = "*"` and `Resource = "*"` in production.

Example least-privilege policy for reading from one bucket:

```hcl
policy_document = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::my-app-bucket",
        "arn:aws:s3:::my-app-bucket/*"
      ]
    }
  ]
})
```

## Instance profile

An IAM instance profile is a container for an IAM role that EC2 instances can reference. When an EC2 instance is launched with an instance profile, the instance can assume the role and access AWS services securely — no credentials needed on the instance.

Instance profiles are only needed for EC2. For Lambda, ECS, or other services, the service handles role assumption directly and you do not need an instance profile.

Set `create_instance_profile = true` when you need to attach this role to an EC2 instance.

## Session duration

`max_session_duration` controls how long assumed role sessions can last. The default is 3600 seconds (1 hour), which is the AWS default. You can increase this to up to 43200 seconds (12 hours) if your use case requires longer sessions.

Longer sessions mean fewer role assumption calls, but also mean longer exposure if credentials are leaked.

## Outputs

- `role_name` — name of the IAM role
- `role_arn` — ARN of the IAM role
- `role_unique_id` — stable unique ID of the role
- `policy_arn` — ARN of the policy (null if `create_policy = false`)
- `policy_id` — ID of the policy (null if `create_policy = false`)
- `instance_profile_name` — name of the instance profile (null if `create_instance_profile = false`)
- `instance_profile_arn` — ARN of the instance profile (null if `create_instance_profile = false`)

## Usage

### Basic role with policy

```hcl
module "app_role" {
  source = "../../modules/iam"

  role_name = "my-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::my-app-bucket/*"
      }
    ]
  })

  tags = {
    Project     = "my-app"
    Environment = "prod"
  }
}
```

### Role for EC2 with instance profile

```hcl
module "ec2_role" {
  source = "../../modules/iam"

  role_name = "ec2-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })

  create_instance_profile = true

  tags = {
    Project = "my-app"
  }
}

# Use the instance profile when launching EC2
resource "aws_instance" "app" {
  # ...
  iam_instance_profile = module.ec2_role.instance_profile_name
}
```

### Role without a policy (attach externally)

```hcl
module "role_only" {
  source = "../../modules/iam"

  role_name = "cross-account-role"
  create_policy = false

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:root"
        }
      }
    ]
  })
}
```

## Cost notes

IAM roles, policies, and instance profiles are **free**. There is no charge for creating or using IAM resources.

## Security best practices

- **Least privilege:** Only grant the permissions the role actually needs
- **Scoped resources:** Use specific ARNs instead of `*` wherever possible
- **No wildcard actions:** Avoid `Action = "*"` unless absolutely required
- **Review periodically:** IAM policies can accumulate unused permissions over time
- **Separate roles by purpose:** Create different roles for different workloads rather than one broad role

## Notes

- IAM policy documents use the IAM policy grammar, not Terraform syntax. Use `jsonencode()` in Terraform to build them.
- Role names are unique within an AWS account, but not globally.
- Instance profiles can take a few moments to become available after creation.
- You cannot delete an instance profile while it is attached to a running EC2 instance.
- The default policy document is a placeholder. Replace it with your actual permissions before applying.

# ECR Module

Reusable Terraform module that creates an Amazon Elastic Container Registry (ECR) repository with optional lifecycle policies and repository policies.

## What it creates

- 1 ECR repository
- Optional: 1 lifecycle policy (for image cleanup)
- Optional: 1 repository policy (for access control)

## Important inputs

| Input | Required | Default | Notes |
|-------|----------|---------|-------|
| `repository_name` | yes | none | Name of the ECR repo |
| `image_tag_mutability` | no | `MUTABLE` | `MUTABLE` or `IMMUTABLE` |
| `scan_on_push` | no | `true` | Scan images for CVEs |
| `encryption_type` | no | `AES256` | `AES256` or `aws:kms` |
| `kms_key_id` | no | `null` | KMS key for encryption |
| `lifecycle_policy` | no | `null` | Image cleanup rules |
| `repository_policy` | no | `null` | Access control policy |
| `tags` | no | `{}` | Additional tags |

## ECR repository

ECR is AWS's managed container image registry. It stores Docker images and OCI artifacts.

### Repository name

Repository names must be unique within your AWS account and region. Use descriptive names:

```hcl
repository_name = "my-app"
```

Or include more context:

```hcl
repository_name = "production/web-api"
```

### Image tag mutability

- **MUTABLE** (default): Tags can be overwritten. Pushing `latest` updates the tag.
- **IMMUTABLE**: Tags cannot be overwritten once pushed. This prevents accidental overwrites.

Use `IMMUTABLE` for production repositories where you want to ensure image integrity.

```hcl
image_tag_mutability = "IMMUTABLE"
```

### Image scanning

Scanning is enabled by default. ECR uses Clair to scan images for CVEs and reports findings.

```hcl
scan_on_push = true  # Default — scan on every push
```

Scanning is free, but you should review findings and patch vulnerable images.

### Encryption

Repositories are encrypted by default using AES256 (S3-managed keys). For stronger control, use KMS:

```hcl
encryption_type = "aws:kms"
kms_key_id      = aws_kms_key.ecr.arn
```

## Lifecycle policies

Lifecycle policies automate image cleanup to control storage costs. Without lifecycle policies, old images accumulate and increase costs.

### Keep only the N most recent images

```hcl
lifecycle_policy = {
  rules = [
    {
      rulePriority = 1
      description  = "Keep only last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }
  ]
}
```

### Keep images by age

```hcl
lifecycle_policy = {
  rules = [
    {
      rulePriority = 1
      description  = "Expire images older than 30 days"
      selection = {
        tagStatus   = "any"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = 30
      }
      action = {
        type = "expire"
      }
    }
  ]
}
```

### Keep tagged images, expire untagged

```hcl
lifecycle_policy = {
  rules = [
    {
      rulePriority = 1
      description  = "Keep tagged images"
      selection = {
        tagStatus = "tagged"
        countType = "imageCountMoreThan"
        countNumber = 50
      }
      action = {
        type = "expire"
      }
    },
    {
      rulePriority = 2
      description  = "Expire untagged images after 24 hours"
      selection = {
        tagStatus   = "untagged"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = 1
      }
      action = {
        type = "expire"
      }
    }
  ]
}
```

## Repository policies

Repository policies control access to the repository. By default, no policy is set — access is controlled via IAM.

### Allow an IAM role to pull images

```hcl
repository_policy = {
  Version = "2012-10-17"
  Statement = [
    {
      Sid    = "AllowPull"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::123456789012:role/my-app-role"
      }
      Action = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ]
      Resource = "*"
    }
  ]
}
```

### Allow cross-account access

```hcl
repository_policy = {
  Version = "2012-10-17"
  Statement = [
    {
      Sid    = "AllowCrossAccountPull"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::987654321098:root"
      }
      Action = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ]
      Resource = "*"
    }
  ]
}
```

### Allow push and pull from a specific account

```hcl
repository_policy = {
  Version = "2012-10-17"
  Statement = [
    {
      Sid    = "AllowPushPull"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::123456789012:root"
      }
      Action = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ]
      Resource = "*"
    }
  ]
}
```

## Outputs

- `repository_id` — ID of the ECR repository
- `repository_arn` — ARN of the ECR repository
- `repository_url` — URL for docker push/pull (includes account and region)
- `repository_name` — name of the repository
- `registry_id` — AWS account ID
- `repository_uri` — URI of the repository

## Usage

### Basic ECR repository

```hcl
module "ecr" {
  source = "../../modules/ecr"

  repository_name        = "my-app"
  image_tag_mutability   = "MUTABLE"
  scan_on_push           = true
  encryption_type        = "AES256"

  tags = {
    Project     = "my-app"
    Environment = "prod"
  }
}

output "ecr_url" {
  value = module.ecr.repository_url
}
```

### Production ECR with immutability and lifecycle

```hcl
module "ecr" {
  source = "../../modules/ecr"

  repository_name        = "production/web-api"
  image_tag_mutability   = "IMMUTABLE"
  scan_on_push           = true
  encryption_type        = "aws:kms"
  kms_key_id              = aws_kms_key.ecr.arn

  lifecycle_policy = {
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 20 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 20
        }
        action = {
          type = "expire"
        }
      }
    ]
  }

  tags = {
    Project = "web-api"
  }
}
```

## Using with Docker

After creating the repository, authenticate Docker and push images:

```bash
# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

# Tag and push
docker tag my-app:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```

The `repository_url` output gives you the registry URL.

## Using with ECS or EKS

For ECS task definitions, reference the ECR image:

```hcl
resource "aws_ecs_task_definition" "app" {
  family                   = "my-app"
  container_definitions    = jsonencode([{
    name  = "app"
    image = "${module.ecr.repository_url}:latest"
    # ...
  }])

  # ...
}
```

For EKS, create an imagePullSecrets or use IAM roles for service accounts (IRSA).

## Cost notes

ECR pricing includes:

- **Storage:** per-GiB-month (~$0.10/GiB-month in us-east-1)
- **Data transfer:** outbound data transfer costs apply
- **Image scanning:** free
- **Repository:** free (pay only for storage)

A repository with a few images typically costs less than $1/month.

**Clean up old images** using lifecycle policies to control costs.

## Security best practices

- **Enable scan_on_push** to catch vulnerabilities early
- **Use IMMUTABLE tags** in production to prevent overwrites
- **Encrypt with KMS** for stronger key control
- **Use repository policies** to restrict access, especially for public or cross-account access
- **Avoid public repositories** unless intentionally publishing images
- **Review scan findings** and patch vulnerable images

## Notes

- ECR is regional — repositories exist in a specific region
- Image tags are mutable by default; set `image_tag_mutability = "IMMUTABLE"` to prevent overwrites
- Lifecycle policies are evaluated once per day
- Repository policies use IAM policy grammar
- ECR requires authentication for push/pull (use `aws ecr get-login-password` or IAM roles)

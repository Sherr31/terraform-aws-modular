# S3 Module

Reusable Terraform module that creates an S3 bucket with secure defaults: encryption enabled, public access blocked, and modern object ownership settings.

## What it creates

- 1 S3 bucket
- Server-side encryption configuration (AES256 by default)
- Public access block (all blocks enabled by default)
- Object ownership controls (BucketOwnerEnforced by default)
- Optional versioning
- Optional lifecycle rules for cost management
- Optional ACL (ignored when BucketOwnerEnforced)

## Important inputs

| Input | Required | Default | Notes |
|-------|----------|---------|-------|
| `bucket_name` | yes | none | Globally unique bucket name |
| `tags` | no | `{}` | Additional tags |
| `versioning_enabled` | no | `false` | Enable object versioning |
| `sse_algorithm` | no | `AES256` | `AES256` or `aws:kms` |
| `kms_key_id` | no | `null` | KMS key for `aws:kms` encryption |
| `block_public_acls` | no | `true` | Block public ACLs |
| `block_public_policy` | no | `true` | Block public policies |
| `ignore_public_acls` | no | `true` | Ignore public ACLs |
| `restrict_public_buckets` | no | `true` | Restrict public access |
| `object_ownership` | no | `BucketOwnerEnforced` | Object ownership model |
| `acl` | no | `null` | Canned ACL (ignored with BucketOwnerEnforced) |
| `lifecycle_rules` | no | `[]` | Lifecycle rules for cost control |

## Security defaults

The module applies these secure defaults:

- **Encryption:** AES256 server-side encryption enabled by default
- **Public access:** All four public access block settings enabled by default
- **Object ownership:** BucketOwnerEnforced (ACLs disabled) by default

These defaults follow AWS security best practices for new S3 buckets.

## Bucket naming

S3 bucket names must be **globally unique** across all AWS accounts. When using this module, pass in a name that includes enough context to be unique:

```hcl
bucket_name = "myapp-prod-logs-123456789012"
```

A common pattern is to include the project name, environment, and optionally the account ID.

## Versioning

Versioning is **disabled by default** to keep costs predictable.

Enable it when you need:
- Protection against accidental deletion
- Object history/rollback capability
- Compliance requirements for object retention

Cost note: versioning increases storage costs because older versions are retained until explicitly deleted or expired via lifecycle rules.

## Lifecycle rules

Lifecycle rules help control costs by automatically managing objects over time. Common uses:

- **Transition to cheaper storage:** Move objects to Standard-Infrequent Access or Glacier after a period of inactivity
- **Expiration:** Delete objects after a retention period
- **Version cleanup:** Expire old versions in versioned buckets

Example with transitions and expiration:

```hcl
lifecycle_rules = [
  {
    id     = "log-archive"
    status = "Enabled"
    transitions = [
      {
        days          = 90
        storage_class = "STANDARD_IA"
      },
      {
        days          = 180
        storage_class = "GLACIER"
      }
    ]
    expiration = {
      days = 365
    }
  }
]
```

## Public access

All four public access block settings are enabled by default:

- `block_public_acls` — prevents public ACLs
- `block_public_policy` — prevents public bucket policies
- `ignore_public_acls` — ignores public ACLs on objects
- `restrict_public_buckets` — limits public bucket policies to AWS services

If you need to allow public access (for example, for a static website), set these to `false` explicitly. Do not do this by accident.

## Encryption

The module supports two encryption modes:

- **AES256 (default):** S3-managed encryption keys. No additional setup needed.
- **aws:kms:** AWS KMS-managed keys. Set `kms_key_id` to use a specific KMS key, or leave it null to use the S3-managed KMS key (`aws/s3`).

## Object ownership

The default `BucketOwnerEnforced` setting disables ACLs entirely and makes the bucket owner the owner of all objects. This is the recommended setting for new buckets and simplifies access control.

If you need ACL-based access (for cross-account uploads where the uploading account should own objects), set `object_ownership` to `ObjectWriter`.

## Outputs

- `bucket_id` — bucket ID
- `bucket_arn` — bucket ARN
- `bucket_domain_name` — bucket domain name (for accessing objects)
- `bucket_region` — bucket's AWS region
- `bucket_name` — bucket name (same as bucket_id for S3)

## Usage

This is a child module. Do not apply it directly. Call it from a root configuration.

```hcl
module "s3_bucket" {
  source = "../../modules/s3"

  bucket_name        = "myapp-dev-assets-123456789012"
  versioning_enabled = false
  tags = {
    Project     = "myapp"
    Environment = "dev"
  }
}
```

## Cost notes

- S3 storage: per-GiB-month pricing varies by storage class
- Versioning: retains old versions, increasing storage costs
- Lifecycle transitions: moving to IA or Glacier can reduce costs
- PUT/GET/COPY/POST/LIST requests: per-1000-request pricing
- Data transfer: egress to internet costs money; inbound is free

Destroy the bucket and its contents when you're done with a lab. Empty the bucket first if it has objects.

## Notes

- The bucket name is the unique identifier and becomes part of the bucket's ARN and domain name.
- This module does not create bucket policies. Add a `aws_s3_bucket_policy` resource in the root configuration if you need custom policies.
- This module does not configure static website hosting. Use a separate configuration or module for that use case.
- After creation, the bucket may take a few moments to be fully ready for some operations.

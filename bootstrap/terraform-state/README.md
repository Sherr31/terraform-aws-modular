# Bootstrap — Terraform State Infrastructure

This bootstrap configuration creates the S3 bucket and DynamoDB table used for Terraform remote state across the entire project.

## What it creates

- 1 S3 bucket for Terraform state files
- S3 Bucket Policy enforcing HTTPS-only access
- S3 Block Public Access (all settings enabled)
- Server-side encryption (AES256)
- S3 versioning (for state file history)
- S3 lifecycle rules (to control version cleanup costs)
- 1 DynamoDB table for state locking
- Optional: IAM policy for least-privilege access

## Why this exists

Every independent Terraform configuration in this project (examples, apps) needs a remote backend. This bootstrap creates that backend infrastructure once, and all other configurations reference it.

## Security

The state bucket is configured with defense-in-depth security:

| Setting | Value | Why |
|---------|-------|-----|
| Block Public Access | All enabled | State must never be public |
| Encryption (at rest) | AES256 | Encrypt state on disk |
| Enforced HTTPS (in transit) | Deny all non-HTTPS requests | Protect state data while traveling over the network |
| Versioning | Enabled | Recover from accidental changes |
| Lifecycle | 30-day non-current version expiration | Control storage costs |
| State locking | DynamoDB table | Prevent concurrent writes from corrupting state |

State files can contain sensitive data (resource IDs, IPs, sometimes secrets in variables). Encrypting at rest and enforcing HTTPS in transit are both essential.

### How HTTPS enforcement works

The bucket policy contains a single **Deny** statement:

```hcl
{
  "Sid": "EnforceHTTPS",
  "Effect": "Deny",
  "Principal": "*",
  "Action": "s3:*",
  "Resource": ["arn:aws:s3:::your-bucket", "arn:aws:s3:::your-bucket/*"],
  "Condition": {
    "Bool": {
      "aws:SecureTransport": "false"
    }
  }
}
```

This says: **deny any S3 operation on this bucket unless the request used HTTPS.**

Key points:

- `Principal = "*"` means this applies to **everyone**, including the bucket owner
- It is a **Deny**, so it overrides any IAM Allow — even if IAM says a user can access the bucket, the bucket policy blocks them if they use HTTP
- Both the bucket ARN and `/*` are included so the policy covers the bucket itself and all objects inside it
- `aws:SecureTransport = "false"` is the condition — if the request did NOT use SSL/TLS (i.e., it used plain HTTP), the condition is true, and the Deny applies

This is a zero-trust transport layer: no exceptions, no exemptions.

### Why both encryption at rest and HTTPS-in-transit?

They protect different things:

- **Encryption at rest (AES256):** Protects the state file if someone gains access to the S3 storage layer (e.g., AWS internal storage, backup media)
- **HTTPS enforcement:** Protects the state file while it is being transferred over the network (e.g., during `terraform init`, `terraform plan`, `terraform apply`)

A state file could be encrypted on disk but still exposed in plaintext over an unencrypted HTTP connection if someone intercepts the traffic. Both controls are needed.

## State locking

State locking prevents concurrent modifications that could corrupt state. The DynamoDB table provides this using the `dynamodb:GetItem`, `dynamodb:PutItem`, `dynamodb:UpdateItem`, and `dynamodb:DeleteItem` actions in the IAM access policy.

Without locking, two people running `terraform apply` at the same time could corrupt the state file.

### DynamoDB vs S3 native locking

Two locking mechanisms exist:

| Feature | DynamoDB (current) | S3 native (`use_lockfile = true`) |
|---------|-------------------|-----------------------------------|
| Terraform version requirement | Any version | Terraform 1.10+ |
| Region support | All regions | All regions |
| Extra resource | 1 DynamoDB table (pay-per-request) | None |
| Lock visibility | Visible in DynamoDB console | Managed internally by S3 |
| Maturity | Battle-tested for years | Newer feature |

For this project, DynamoDB is the better choice because it is already implemented, is compatible with all Terraform versions, and provides visibility into lock state. The DynamoDB cost is negligible (pay-per-request, typically pennies per month).

If you ever want to switch to S3 native locking, you would:

1. Remove the DynamoDB table from the bootstrap
2. Change the IAM policy to remove DynamoDB permissions
3. Update all backend configurations to remove the DynamoDB table reference
4. Migrate state (which preserves existing locks)

This is not recommended unless you have a specific reason to simplify the bootstrap.

## Cost

- **S3 bucket:** ~$0.023/GB-month for storage. State files are typically small (KB to low MB).
- **S3 versioning:** Old versions consume storage. The lifecycle rule deletes versions older than 30 days.
- **DynamoDB:** Pay-per-request mode — typically pennies per month for state locking traffic.

Total cost: usually under $1/month for a small project.

## Usage

### 1) Initialize and validate

```bash
cd bootstrap/terraform-state

terraform fmt -check
terraform fmt
terraform init -backend=false
terraform validate
```

### 2) Plan

```bash
terraform plan -var="bucket_name=mycompany-terraform-state-123456789012"
```

### 3) Apply

```bash
terraform apply -var="bucket_name=mycompany-terraform-state-123456789012"
```

**Important:** Choose a globally unique bucket name. S3 bucket names are globally unique across all AWS accounts.

### 4) Use the outputs

After applying, use the outputs to configure backends in other configurations:

```hcl
# In examples/vpc/backend.tf
terraform {
  backend "s3" {
    bucket       = "mycompany-terraform-state-123456789012"
    key          = "examples/vpc/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

## Configuring backends in other configurations

Each example and app should have its own `backend.tf` with a unique state key. The backend configuration must include the DynamoDB table for locking:

```hcl
# In examples/vpc/backend.tf
terraform {
  backend "s3" {
    bucket       = "your-bucket-name"     # from bootstrap output
    key          = "examples/vpc/terraform.tfstate"
    region       = "us-east-1"            # or your preferred region
    encrypt      = true
    dynamodb_table = "your-lock-table-name"  # from bootstrap output
  }
}
```

Each example and app gets its own state key:

```
examples/vpc/terraform.tfstate
examples/ec2/terraform.tfstate
examples/s3/terraform.tfstate
examples/iam/terraform.tfstate
examples/security-group/terraform.tfstate
examples/alb/terraform.tfstate
examples/autoscaling/terraform.tfstate
examples/ecr/terraform.tfstate
```

### Why separate state files matter

Each independent root configuration (examples, apps) gets its own state file with its own key. This is important because:

- **Isolation:** If `examples/vpc` modifies its VPC, it only touches `examples/vpc/terraform.tfstate`. It cannot accidentally modify `examples/ec2`'s state.
- **Blast radius:** A problem in one configuration's state (corruption, accidental deletion) only affects that configuration, not the entire project.
- **Permissions:** You can grant different teams or users access to different state keys without giving them access to everything.
- **Lifecycle:** You can destroy one configuration (e.g., a lab example) and destroy only its state, leaving other configurations untouched.

If all configurations shared a single state file, a `terraform destroy` in one example would destroy everything the state tracked — including resources from other examples. Separate state files prevent this.

## Migration from local state

If you've been using local state and want to migrate to the remote backend:

1. Create the bootstrap infrastructure first
2. Add `backend.tf` to the configuration
3. Run:

```bash
terraform init -migrate-state
```

Terraform will detect the backend change and ask if you want to migrate. Say "yes" to copy the local state to S3.

**Always back up your local state before migrating:**

```bash
cp terraform.tfstate terraform.tfstate.backup
```

## Protecting the bootstrap state

The bootstrap configuration manages the state storage for the entire project. Protect it:

- **Enable MFA delete** on the bucket for extra protection (advanced)
- **Use IAM policies** to restrict who can modify the bucket
- **Enable S3 Object Lock** in governance or compliance mode (advanced)
- **Back up the state regularly**

## Destroying

To destroy the bootstrap infrastructure:

```bash
terraform destroy -var="bucket_name=mycompany-terraform-state-123456789012"
```

**Warning:** This deletes the state bucket and everything in it. All other configurations that use this backend will lose their state.

- Set `force_destroy = true` to allow destruction of a non-empty bucket
- In production, leave `force_destroy = false` to prevent accidental destruction

## Notes

- The bucket name must be globally unique. Include your account ID or organization name.
- The DynamoDB table uses pay-per-request billing to minimize costs.
- The access policy is optional. You can manage access separately via IAM.
- After the bootstrap is created, you can configure the bootstrap's own backend to use the bucket it created (by migrating state).

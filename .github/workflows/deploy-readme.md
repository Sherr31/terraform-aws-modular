# Terraform Deploy Workflow — Setup Guide

The `terraform-deploy.yml` workflow deploys AWS infrastructure from approved Terraform configurations. It uses GitHub OIDC for authentication and requires manual approval before applying changes.

## How it works

```
User triggers workflow_dispatch
   │
   ▼
Select configuration (dropdown) + optional variables
   │
   ▼
Workflow authenticates to AWS via OIDC
   │
   ▼
terraform init → validate → fmt check → plan
   │
   ▼
Plan saved as encrypted artifact
   │
   ▼
[ Manual approval required (GitHub Environment) ]
   │
   ▼
terraform apply (exact plan from artifact)
   │
   ▼
Outputs shown, deployment summary written
```

## Prerequisites

### 1. Deploy the bootstrap infrastructure

The remote state backend must exist before any deployment can run:

```bash
cd bootstrap/terraform-state
terraform apply -var="bucket_name=your-unique-bucket-name"
```

Save the bucket name and DynamoDB table name from the outputs.

### 2. Configure backend.tf files

Each configuration's `backend.tf` has placeholder values:

```hcl
bucket       = "BUCKET_NAME"        # Replace with actual bucket name
dynamodb_table = "LOCK_TABLE_NAME"  # Replace with actual table name
```

Replace `BUCKET_NAME` and `LOCK_TABLE_NAME` in each `backend.tf` with the actual values from the bootstrap outputs.

### 3. Set up GitHub OIDC trust with AWS

This is a one-time setup. Follow these steps:

#### a) Create the OIDC identity provider in AWS

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

#### b) Create the IAM role for Terraform deployments

Create a role with a trust policy that allows GitHub OIDC to assume it:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:YOUR-GITHUB-ORG/terraform-aws-modular:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

Replace `YOUR_ACCOUNT_ID` and `YOUR-GITHUB-ORG` with your actual values.

The `sub` condition restricts the role to be assumable only from your repository on the `main` branch. Adjust this condition if you want to allow deployments from other branches or environments.

#### c) Attach permissions to the role

The role needs permissions to manage the AWS resources created by your Terraform configurations. The minimum permissions depend on which configurations you plan to deploy.

For a full-featured deployment role (can deploy all configurations in this project):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowEC2",
      "Effect": "Allow",
      "Action": [
        "ec2:AllocateAddress",
        "ec2:AssociateAddress",
        "ec2:CreateInternetGateway",
        "ec2:CreateNetworkInterface",
        "ec2:CreateRoute",
        "ec2:CreateRouteTable",
        "ec2:CreateSecurityGroup",
        "ec2:CreateSubnet",
        "ec2:CreateTags",
        "ec2:CreateVpc",
        "ec2:DeleteInternetGateway",
        "ec2:DeleteNetworkInterface",
        "ec2:DeleteRoute",
        "ec2:DeleteRouteTable",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteSubnet",
        "ec2:DeleteVpc",
        "ec2:DescribeAccountAttributes",
        "ec2:DescribeAddresses",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInstances",
        "ec2:DescribeInternetGateways",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeRouteTables",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcs",
        "ec2:DescribeVpcAttribute",
        "ec2:DescribeVpcClassicLink",
        "ec2:DescribeVpcClassicLinkDnsSupport",
        "ec2:DisassociateAddress",
        "ec2:ModifyVpcAttribute",
        "ec2:ReleaseAddress",
        "ec2:ReplaceRoute",
        "ec2:ReplaceRouteTableAssociation",
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:CreateLaunchTemplate",
        "ec2:CreateLaunchTemplateVersion",
        "ec2:DeleteLaunchTemplate",
        "ec2:DescribeLaunchTemplates",
        "ec2:DescribeLaunchTemplateVersions",
        "ec2:DeleteLaunchTemplateVersions",
        "ec2:CreateFleet",
        "ec2:DescribeFleets",
        "ec2:DeleteFleet"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowS3Bucket",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:DeleteBucketPolicy",
        "s3:DeleteBucketWebsite",
        "s3:DeleteBucketEncryption",
        "s3:DeleteBucketPublicAccessBlock",
        "s3:DeleteBucketRequestPayment",
        "s3:DeleteBucketVersioning",
        "s3:PutBucketPolicy",
        "s3:PutBucketWebsite",
        "s3:PutBucketEncryption",
        "s3:PutBucketPublicAccessBlock",
        "s3:PutBucketRequestPayment",
        "s3:PutBucketVersioning",
        "s3:GetBucketPolicy",
        "s3:GetBucketWebsite",
        "s3:GetBucketEncryption",
        "s3:GetBucketPublicAccessBlock",
        "s3:GetBucketRequestPayment",
        "s3:GetBucketVersioning",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::your-terraform-state-bucket",
        "arn:aws:s3:::your-terraform-state-bucket/*"
      ]
    },
    {
      "Sid": "AllowDynamoDB",
      "Effect": "Allow",
      "Action": [
        "dynamodb:CreateTable",
        "dynamodb:DeleteTable",
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/terraform-state-locks"
    },
    {
      "Sid": "AllowELB",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:AddListenerCertificates",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:CreateRule",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DeleteRule",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeLoadBalancerAttributes",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeRules",
        "elasticloadbalancing:DescribeSSLPolicies",
        "elasticloadbalancing:DescribeTags",
        "elasticloadbalancing:DescribeTargetGroupAttributes",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:ModifyRule",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:RemoveListenerCertificates",
        "elasticloadbalancing:RemoveTags",
        "elasticloadbalancing:SetIpAddressType",
        "elasticloadbalancing:SetSecurityGroups",
        "elasticloadbalancing:SetSubnets",
        "elasticloadbalancing:SetWebAcl"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowAutoScaling",
      "Effect": "Allow",
      "Action": [
        "autoscaling:CreateAutoScalingGroup",
        "autoscaling:CreateLaunchConfiguration",
        "autoscaling:CreateOrUpdateTags",
        "autoscaling:DeleteAutoScalingGroup",
        "autoscaling:DeleteLaunchConfiguration",
        "autoscaling:DeletePolicy",
        "autoscaling:DeleteScheduledAction",
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribePolicies",
        "autoscaling:DescribeScalingActivities",
        "autoscaling:DescribeScheduledActions",
        "autoscaling:DetachInstances",
        "autoscaling:EnableMetricsCollection",
        "autoscaling:PutScalingPolicy",
        "autoscaling:PutScheduledUpdateGroupAction",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:UpdateAutoScalingGroup",
        "autoscaling:EnterStandby",
        "autoscaling:ExitStandby",
        "autoscaling:AttachInstances",
        "autoscaling:SuspendProcesses",
        "autoscaling:ResumeProcesses",
        "autoscaling:RecordLifecycleActionHeartbeat",
        "autoscaling:CompleteLifecycleAction",
        "autoscaling:SetInstanceProtection",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "autoscaling:StartInstanceRefresh",
        "autoscaling:CancelInstanceRefresh",
        "autoscaling:DescribeInstanceRefreshes"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowIAM",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:CreateInstanceProfile",
        "iam:DeleteRole",
        "iam:DeleteInstanceProfile",
        "iam:DeleteRolePolicy",
        "iam:GetRole",
        "iam:GetInstanceProfile",
        "iam:PutRolePolicy",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:ListRoles",
        "iam:ListInstanceProfiles"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowECR",
      "Effect": "Allow",
      "Action": [
        "ecr:CreateRepository",
        "ecr:DeleteRepository",
        "ecr:DescribeRepositories",
        "ecr:PutLifecyclePolicy",
        "ecr:GetRepositoryPolicy",
        "ecr:SetRepositoryPolicy",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowKMS",
      "Effect": "Allow",
      "Action": [
        "kms:CreateGrant",
        "kms:DescribeKey",
        "kms:GenerateDataKey",
        "kms:Decrypt",
        "kms:Encrypt"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowCloudWatch",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:DeleteAlarms"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowSTS",
      "Effect": "Allow",
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**Important:** This is a broad permission set. For production use, consider creating separate roles with narrower permissions per environment or per configuration.

#### d) Store the role ARN in GitHub Secrets

In your GitHub repository, go to Settings → Secrets and variables → Actions, and add:

| Secret name | Value |
|-------------|-------|
| `AWS_ROLE_ARN` | `arn:aws:iam::YOUR_ACCOUNT_ID:role/terraform-deploy-role` |

#### e) Configure the GitHub Environment

In your GitHub repository, go to Settings → Environments:

1. Click "New environment"
2. Name it `terraform-deployment`
3. Optionally add required reviewers (people who must approve deployments)
4. Optionally set a wait timer
5. Save

If you don't configure an environment, the workflow will skip approval and apply immediately (if `auto_apply` is false but `environment_name` is empty).

### 4. Verify the setup

Trigger the workflow manually from the Actions tab:

1. Go to Actions → "Terraform Deploy" → "Run workflow"
2. Select a configuration (e.g., `examples/s3`)
3. Leave extra variables empty (the S3 example doesn't require any)
4. Set `auto_apply` to `true` for the first run (to test without approval)
5. Click "Run workflow"

Watch the workflow run. It should:
1. Check out the code
2. Authenticate to AWS via OIDC
3. Initialize Terraform with the remote backend
4. Validate the configuration
5. Check formatting
6. Generate a plan
7. Apply the plan (because auto_apply is true)
8. Show outputs

If the workflow fails at the init step, check that:
- The backend.tf has the correct bucket name and DynamoDB table name
- The bootstrap infrastructure was deployed successfully
- The OIDC trust policy is correct

## Workflow inputs

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `configuration` | choice | `examples/vpc` | Terraform root configuration to deploy |
| `extra_vars` | string | `{}` | Extra Terraform variables as JSON object |
| `auto_apply` | boolean | `false` | Skip manual approval and apply immediately |
| `environment_name` | string | `terraform-deployment` | GitHub Environment for approval |

## Workflow permissions

| Permission | Purpose |
|------------|---------|
| `contents: read` | Check out the repository code |
| `id-token: write` | Request OIDC token for AWS authentication |
| `actions: write` | Upload/download artifacts, write deployment summary |

## Security considerations

- **No long-lived credentials:** AWS access is via OIDC, which issues short-lived tokens (1 hour max). Even if the token is leaked, it expires quickly.
- **Repository-scoped trust:** The OIDC trust policy restricts the role to be assumable only from your specific repository and branch.
- **Manual approval:** The default workflow requires manual approval via GitHub Environment before applying changes. This prevents accidental deployments.
- **Plan artifact:** The plan is stored as an encrypted artifact, not printed to logs. Reviewers can inspect it before approving.
- **Exact plan apply:** The apply step uses the exact plan file that was reviewed, preventing drift between plan and apply.
- **No destroy:** This workflow does not support `terraform destroy`. Destroying infrastructure requires a separate, more deliberate process.

## Limitations

- **Single configuration per run:** You can only deploy one configuration at a time. To deploy multiple configurations, run the workflow multiple times.
- **No dependency ordering:** The workflow does not understand dependencies between configurations. If `examples/ec2` depends on `examples/vpc`, you must deploy VPC first.
- **No automatic rollback:** If a deployment fails during apply, Terraform will attempt to roll back, but complex failures may leave partial infrastructure. Always review the plan before approving.
- **No state migration:** The workflow assumes the backend is already configured. It does not migrate state from local to remote.
- **No destroy support:** There is no `terraform destroy` capability in this workflow. Destroying infrastructure requires a separate workflow or manual process.

## Troubleshooting

### Workflow fails at init: "No valid credential sources found"

The OIDC authentication failed. Check:
- The `AWS_ROLE_ARN` secret is set correctly
- The IAM role's trust policy allows your repository
- The `sub` condition matches your repository and branch
- The role has the `sts:AssumeRoleWithWebIdentity` action allowed

### Workflow fails at init: "Bucket not found" or "Table not found"

The backend configuration has incorrect values. Check:
- The `backend.tf` has the actual bucket name and table name (not placeholders)
- The bootstrap infrastructure was deployed successfully
- The AWS credentials have permission to access the bucket and table

### Plan shows unexpected changes

The plan shows changes that you didn't expect. This could mean:
- The configuration was modified since the last apply
- The backend state is out of sync
- Someone applied changes manually in the AWS console

Review the plan carefully before approving.

### Apply fails with "Resource already exists"

A resource with the same name already exists. This could mean:
- The resource was created manually in the AWS console
- A previous deployment failed partway and left resources behind
- The state file is out of sync

Check the AWS console and the Terraform state to understand what exists.

## References

- [GitHub OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [AWS Actions: configure-aws-credentials](https://github.com/aws-actions/configure-aws-credentials)
- [Terraform Cloud: GitHub Actions integration](https://developer.hashicorp.com/terraform/cloud-docs/git/externals) (concepts apply to self-managed backends too)

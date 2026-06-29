# Deployment Guide

This document explains how to reproduce the entire Massar infrastructure from scratch in your own AWS account. Follow the phases in order — each phase is a prerequisite for the next.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Repository Configuration](#repository-configuration)
- [Phase 1 — Bootstrap: Remote State Bucket](#phase-1--bootstrap-remote-state-bucket)
- [Phase 2 — Bootstrap: OIDC & IAM Roles](#phase-2--bootstrap-oidc--iam-roles)
- [Phase 3 — GitHub Actions Secrets](#phase-3--github-actions-secrets)
- [Phase 4 — Main Infrastructure](#phase-4--main-infrastructure)
- [Phase 5 — Budget Module](#phase-5--budget-module)
- [CI/CD Pipeline Operation](#cicd-pipeline-operation)
- [Variable Reference](#variable-reference)
- [Teardown](#teardown)

---

## Prerequisites

### Required Tools

| Tool | Minimum Version | Install |
|---|---|---|
| Terraform | `>= 1.15.0` | [developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install) |
| AWS CLI | `>= 2.x` | [docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) |
| Git | any | [git-scm.com](https://git-scm.com) |

### AWS Account Requirements

- An AWS account with the ability to create IAM roles and policies.
- `AdministratorAccess` (or equivalent) on your local AWS CLI profile **for the bootstrap phases only**. After bootstrap, all provisioning runs through the scoped `TerraformRole`.
- The AWS provider requires `~> 6.0`. Terraform S3 native state locking (`use_lockfile = true`) requires **Terraform >= 1.10**.
- The architecture uses **two AWS providers simultaneously**: `eu-south-1` (all application resources) and `us-east-1` (WAFv2 and ACM — required by CloudFront). Both regions must be accessible from your account.

> **Important — Enable eu-south-1:** New AWS accounts do not have the Milan region active by default.
> Enable it at: *AWS Console → account menu (top-right) → Account Settings → AWS Regions → eu-south-1 → Enable*

### AWS CLI Authentication (Bootstrap Only)

Configure a profile with administrator-level access for the one-time bootstrap steps:

```bash
aws configure --profile massar-bootstrap
# Enter: Access Key ID, Secret Access Key, eu-south-1, json
```

Export it so Terraform uses it automatically:

```bash
export AWS_PROFILE=massar-bootstrap
```

Verify:

```bash
aws sts get-caller-identity
```

---

## Repository Configuration

Fork this repository to your own GitHub account, then clone it:

```bash
git clone https://github.com/<your-username>/massar-aws-infrastructure.git
cd massar-aws-infrastructure
```

All `terraform.tfvars` files currently contain values specific to the original author (`aymenelk01`, specific bucket names, `eu-south-1`). Update the values in each phase below before running any Terraform command.

---

## Phase 1 — Bootstrap: Remote State Bucket

The main `infra/` module uses an S3 remote backend. That bucket must exist **before** `terraform init` is run against `infra/`. This one-time bootstrap module creates it using a **local** backend, so there is no circular dependency.

### 1. Configure variables

```bash
cd bootstrap-statebucket
```

Create or edit `terraform.tfvars`:

```hcl
environment       = "dev"
aws_region        = "eu-south-1"
state_bucket_name = "your-unique-state-bucket-name"   # must be globally unique across all AWS accounts
service           = "Massar"
```

> S3 bucket names are globally unique. A safe pattern: `massar-tfstate-<your-aws-account-id>`.

### 2. Apply

```bash
terraform init
terraform apply
```

This creates a single private, versioned, AES-256-encrypted S3 bucket with all public access blocked. `force_destroy = true` is set deliberately for this portfolio project to allow clean teardown without manual S3 cleanup.

### 3. Note the bucket name

You will reference it in `infra/backend.tf` in Phase 4.

---

## Phase 2 — Bootstrap: OIDC & IAM Roles

This module provisions the GitHub Actions OIDC Identity Provider in IAM plus two IAM roles:

| Role | Used By | Trust Strategy |
|---|---|---|
| `GitHubActionsTerraformRole` | `terraform.yml` in this repo | `StringLike` — any ref on the infra repo |
| `GitHubActionsDeployRole` | `deploy.yml` in `massar-app` | `StringEquals` — `main` branch only on the app repo |

### 1. Configure variables

```bash
cd bootstrap-oidc
```

Edit `terraform.tfvars`:

```hcl
aws_region               = "eu-south-1"
environment              = "dev"
service                  = "Massar"
github_repo_name         = "massar-aws-infrastructure"  # repo name only — no username prefix
github_app_repo_name     = "massar-app"
github_username          = "your-github-username"
static_bucket_name       = "your-unique-static-bucket"  # must match the value you will set in infra/terraform.tfvars
oidc_terraform_role_name = "GitHubActionsTerraformRole"
oidc_deploy_role_name    = "GitHubActionsDeployRole"
```

### 2. Apply

```bash
terraform init
terraform apply
```

### 3. Capture the role ARNs and Add to GitHub Secrets

Run:
```bash
terraform output
```

You will see:
- `terraform_role_arn`
- `deploy_role_arn`

You must add these ARNs to your GitHub repositories as Action Secrets so the CI/CD workflows can authenticate:

1. **For the infrastructure repository (`massar-aws-infrastructure`):**
   - Go to your GitHub repository -> **Settings** -> **Secrets and variables** -> **Actions**.
   - Click **New repository secret**.
   - Name: `AWS_TERRAFORM_ROLE_ARN`
   - Value: Paste the value of `terraform_role_arn` output.

2. **For the application repository (`massar-app`):**
   - Go to your GitHub repository -> **Settings** -> **Secrets and variables** -> **Actions**.
   - Click **New repository secret**.
   - Name: `AWS_DEPLOY_ROLE_ARN`
   - Value: Paste the value of `deploy_role_arn` output.

> **Note:** The OIDC provider (`token.actions.githubusercontent.com`) is a global IAM resource scoped to the AWS account, not to a region. If one already exists in your account from another project, Terraform handles it gracefully on the first apply.


---

## Phase 3 — GitHub Actions Secrets

No long-lived AWS credentials are used anywhere in this project. Authentication is entirely OIDC-based. The only values stored as GitHub Secrets are the IAM role ARNs that GitHub Actions exchanges for temporary STS credentials at runtime, and a GitHub Personal Access Token (PAT) used for repository dispatch.

### How to generate the `APP_REPO_DISPATCH_TOKEN`

The infrastructure pipeline in `massar-aws-infrastructure` needs to trigger a frontend rebuild/deployment in the `massar-app` repository whenever Cognito configurations change. To authorize this cross-repository trigger, you need to generate a GitHub Personal Access Token (classic):

1. Click your profile picture in the top-right corner of GitHub and go to **Settings**.
2. Scroll down on the left sidebar and click **Developer settings** (at the very bottom).
3. Under **Personal access tokens**, click **Tokens (classic)**.
4. Click the **Generate new token** dropdown and select **Generate new token (classic)**.
5. In the **Note** field, enter a descriptive name (e.g., `massar-infra-dispatch-token`).
6. Choose the appropriate token scope depending on repository visibility:
   - **If `massar-app` is a private repository:** Select the **`repo`** checkbox scope. (This is required by GitHub to trigger repository dispatch events on private repositories, though note it grants full read/write access to all repositories).
   - **If `massar-app` is a public repository:** Select ONLY the **`public_repo`** scope. (This is a much narrower, safer scope that restricts token access to public repositories only, adhering to the principle of least privilege).
7. Scroll to the bottom and click **Generate token**.
8. **Copy the token immediately**—you will not be able to see it again.


---

### Secret Configuration

Configure the secrets in their respective repositories:

#### `massar-aws-infrastructure` repository
Go to **Settings → Secrets and variables → Actions → New repository secret** in your infrastructure repository:

| Secret Name | Value | Description |
|---|---|---|
| `AWS_TERRAFORM_ROLE_ARN` | ARN of `GitHubActionsTerraformRole` | From Phase 2 output |
| `APP_REPO_DISPATCH_TOKEN` | The generated GitHub PAT (classic) | Used to trigger the frontend rebuild in the `massar-app` repository |

#### `massar-app` repository
Go to **Settings → Secrets and variables → Actions → New repository secret** in your application repository:

| Secret Name | Value | Description |
|---|---|---|
| `AWS_DEPLOY_ROLE_ARN` | ARN of `GitHubActionsDeployRole` | From Phase 2 output |

> **Caution:** Do **not** add `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` anywhere. Long-lived credentials are explicitly excluded from this architecture.


---

## Phase 4 — Main Infrastructure

This is the primary Terraform root module. It provisions all application infrastructure: VPC, ECS Fargate, Aurora Serverless v2, RDS Proxy, ElastiCache Redis, CloudFront, WAFv2, Cognito, ECR, S3, Lambda, SQS, VPC Interface Endpoints, and all supporting IAM roles and Security Groups (~200 resources total).

### 1. Update the S3 backend

Open `infra/backend.tf` and set the bucket name to what you created in Phase 1:

```hcl
terraform {
  backend "s3" {
    bucket       = "your-unique-state-bucket-name"
    key          = "infra/terraform.tfstate"
    region       = "eu-south-1"
    use_lockfile = true
    encrypt      = true
  }
}
```

### 2. Configure variables

Create `infra/terraform.tfvars` (this file is gitignored — do not commit it):

```hcl
aws_region            = "eu-south-1"
environment           = "dev"
db_name               = "massardb"
db_username           = "your_db_admin_username"        # avoid AWS reserved words: admin, root, master, user
documents_bucket_name = "your-unique-documents-bucket"
static_bucket_name    = "your-unique-static-bucket"     # must match bootstrap-oidc value exactly
logs_bucket_name      = "your-unique-logs-bucket"
service               = "Massar"
```

> **Important:** `static_bucket_name` must be **identical** in both `bootstrap-oidc/terraform.tfvars` and `infra/terraform.tfvars`. The `GitHubActionsDeployRole` S3 permission is scoped to that exact bucket ARN.

### 3. Initialise

```bash
cd infra
terraform init
```

On first run, Terraform connects to the S3 backend from Phase 1 and downloads the AWS provider (~6.x). If `terraform init` fails with a backend connectivity error, confirm the bucket name and region in `backend.tf` exactly match Phase 1.

### 4. Validate and plan

```bash
terraform validate
terraform plan
```

The plan will show approximately 200 resources to be created. Review it before applying, paying attention to any resources marked `forces replacement` — those will destroy and recreate existing resources.

### 5. Apply

```bash
terraform apply
```

The first apply typically takes **15–25 minutes**, dominated by:

| Resource | Approximate Time |
|---|---|
| Aurora Serverless v2 cluster | ~8 min |
| CloudFront distribution propagation | ~5–10 min |
| RDS Proxy creation | ~3 min |

> **First-apply placeholder image:** The ECS task definition is bootstrapped with a public placeholder image (`public.ecr.aws/nginx/nginx:stable-alpine3.20-slim`). This is intentional — it prevents a chicken-and-egg deadlock where ECS requires an ECR image that does not exist yet. The real application image is pushed by the `deploy.yml` pipeline in `massar-app`. Terraform will never overwrite the image field again after the first apply due to `ignore_changes = [container_definitions]`.

### 6. Verify outputs

```bash
terraform output
```

Key outputs to note:

| Output | Description |
|---|---|
| `cloudfront_domain_name` | Public URL of the platform |
| `alb_dns_name` | Internal ALB DNS endpoint |
| `user_pool_id` | Cognito User Pool ID (also written to SSM automatically) |
| `ecr_repository_url` | ECR push target for the app container |
| `flyway_repository_url` | ECR push target for the Flyway migration container |
| `rds_proxy_endpoint` | Writer proxy endpoint (read/write application traffic) |
| `rds_proxy_reader_endpoint` | Reader proxy endpoint (read-only traffic) |

### 7. Deploy the application

The infrastructure is now live, but the ECS service is still running the placeholder image. To deploy the actual application and test the full stack, trigger the app pipeline manually:

```bash
# Clone the app repo if you haven't already
git clone https://github.com/<your-username>/massar-app.git
cd massar-app

# Trigger the full deployment pipeline (migrations + app + static frontend)
gh workflow run deploy.yml
```

The `deploy.yml` pipeline will:
1. Build and push the Flyway migration image to ECR, run schema migrations against Aurora
2. Build and push the app container to ECR, update the ECS service to the new image
3. Read the Cognito User Pool ID and Client ID from SSM Parameter Store, build the Vite frontend, and sync it to S3

Once the workflow completes, the platform is reachable at the `cloudfront_domain_name` from the Terraform output.

> **SES Sandbox Mode Warning:** By default, your AWS SES account is in sandbox mode. You must verify recipient email addresses in the SES console, or request production access, before the notification Lambda can deliver emails successfully.

> **Requires:** The [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated. Alternatively, go to **GitHub → massar-app → Actions → deploy.yml → Run workflow** and trigger it from the UI.


### 8. Testing the Portals (Default Credentials)

To test the application portals after deployment, use the following default credentials:

#### Admin Portal
* **Username:** `admin`
* **Password:** `Massar 2024!`

#### Teacher Portal
* **Username:** `t.bennani`
* **Password:** `Massar2024!`

#### Student Portal
* **Username:** `student massarcode`
* **Password:** `Massar2024!`

---

## Phase 5 — Budget Module

The budget module creates an AWS Budget with a $50/month cap and email alerts at 80% actual and forecasted spend. It is deployed separately to avoid coupling cost controls to the application lifecycle.

### 1. Set your notification email

Open `budget/terraform.tfvars` and set your email address in the `budget_email` variable.

### 2. Apply


```bash
cd budget
terraform init
terraform apply
```

---

## CI/CD Pipeline Operation

Once Phases 3 and 4 are complete, the GitHub Actions pipelines handle all subsequent changes automatically.

### Terraform pipeline (`terraform.yml`)

Triggers on any change to the `infra/**` path.

```
Pull Request → main  (infra/** changed)
└── terraform-validate
      ├── terraform fmt -check          formatting gate
      ├── terraform init
      ├── TFLint                        aws ruleset v0.47.0 + terraform recommended preset
      ├── Checkov (soft_fail: false)    any HIGH finding blocks the PR — cannot be bypassed
      ├── terraform validate
      └── terraform plan                dry-run only, no changes applied

Merge → main  (infra/** changed)
└── terraform-deploy
      ├── terraform init
      ├── terraform plan -out=tfplan
      ├── terraform apply               JSON output piped through jq for readable logs
      ├── terraform output
      ├── [if Cognito changed] setup-cognito-admin.sh
      └── [if Cognito changed] repository_dispatch → massar-app frontend rebuild
```

### Pipeline environment variables

The `terraform.yml` workflow injects Terraform variable values via `TF_VAR_*` environment variables. If you fork this repo, update the `env:` block in `.github/workflows/terraform.yml` to match your own values:

```yaml
env:
  TF_VAR_environment: "dev"
  TF_VAR_aws_region: "eu-south-1"
  TF_VAR_db_name: "massardb"
  TF_VAR_db_username: "your_db_admin_username"
  TF_VAR_documents_bucket_name: "your-unique-documents-bucket"
  TF_VAR_static_bucket_name: "your-unique-static-bucket"
  TF_VAR_logs_bucket_name: "your-unique-logs-bucket"
```

These values are not sensitive — they are resource names and region identifiers. The Aurora master password is never passed through environment variables; it is generated and rotated automatically by AWS Secrets Manager via `manage_master_user_password = true`.

### Cross-repo deployment coordination

```
massar-aws-infrastructure               massar-app
────────────────────────────            ───────────────────────────
terraform-deploy
  └── Cognito created or updated?
        YES → repository_dispatch ────> deploy.yml triggered
                                          ├── deploy-migrations  (Flyway, runs if sql/** changed)
                                          ├── deploy-app         (ECS Fargate image update)
                                          └── deploy-static      (reads new Cognito IDs from SSM → S3)
```

If only application code changes (no `infra/**` path match), the Terraform pipeline does not run. `deploy.yml` in `massar-app` runs independently on push to `main`.

---

## Teardown

Destroy all resources in strict reverse dependency order. Destroying out of order will fail — for example, the state bucket cannot be destroyed while the main module's state still references it.

```bash
# 1. Destroy main infrastructure (~10–15 minutes)
cd infra
terraform destroy

# 2. Destroy the budget
cd ../budget
terraform destroy

# 3. Destroy OIDC provider and IAM roles
cd ../bootstrap-oidc
terraform destroy

# 4. Destroy the state bucket last
cd ../bootstrap-statebucket
terraform destroy
```

> **Caution:** `terraform destroy` on `infra/` permanently deletes the Aurora cluster, all S3 bucket contents (static files, diplomas, access logs), all ECR images, and the CloudFront distribution. There is no undo. The Aurora cluster has `skip_final_snapshot = true` in this portfolio project — no automated snapshot is taken on destroy.

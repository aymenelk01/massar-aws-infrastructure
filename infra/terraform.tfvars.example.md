```sh
aws_region                = "eu-south-1"
environment               = "dev"
db_name                   = "massardb"
db_username               = "your_db_admin_user"
db_password               = "REPLACE_WITH_YOUR_SECURE_PASSWORD"
documents_bucket_name     = "your-unique-documents-bucket"
static_bucket_name        = "your-unique-static-bucket"
state_bucket_name         = "your-unique-state-bucket"
logs_bucket_name          = "your-unique-logs-bucket"
certificate_arn           = "arn:aws:acm:eu-south-1:123456789012:certificate/your-acm-arn-here"
github_repo_name          = "your-github-username/your-repo-name"
github_username           = "your-github-username"
oidc_terraform_role_name  = "GitHubActionsTerraformRole"
oidc_deploy_role_name     = "GitHubActionsDeployRole"

```

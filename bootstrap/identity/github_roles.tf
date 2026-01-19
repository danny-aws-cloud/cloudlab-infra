##############################################
# IAM role assumed by GitHub Actions via OIDC
#
# This role is used by CI/CD pipelines to
# assume AWS permissions using OIDC tokens
# issued by GitHub Actions.
##############################################
resource "aws_iam_role" "github_actions" {
  name = "github-actions-terraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"

        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        Condition = {
          "StringEquals" : {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:danny-aws-cloud/cloudlab-infra:*"
          }
        }
      }
    ]
  })

  tags = {
    Name      = "github-actions-terraform-role"
    ManagedBy = "Terraform"
    Purpose   = "IAM role assumed by GitHub Actions CI/CD pipelines to manage AWS infrastructure via Terraform"
  }
}

##############################
# IAM policy for Terraform backend access from GitHub Actions
#
# This policy allows GitHub Actions CI/CD pipelines to:
# - Read and write Terraform state in S3
# - Use DynamoDB for Terraform state locking
# - Perform basic account introspection required by Terraform
##############################

resource "aws_iam_policy" "github_actions_terraform_backend" {
  name        = "github-actions-terraform-backend"
  description = "Permissions required for Terraform backend (S3 + DynamoDB) used by GitHub Actions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformStateS3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::cloudlab-terraform-state-*",
          "arn:aws:s3:::cloudlab-terraform-state-*/*"
        ]
      },
      {
        Sid    = "TerraformStateLockDynamoDB"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem",
          "dynamodb:DescribeTable"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/cloudlab-terraform-locks"
      },
      {
        Sid    = "TerraformAccountRead"
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity",
          "iam:ListRoles",
          "iam:ListPolicies"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name      = "github-actions-terraform-backend-policy"
    ManagedBy = "Terraform"
    Purpose   = "Allows GitHub Actions to access Terraform remote state and locking resources"
  }
}

##############################
# Attach Terraform backend policy to GitHub Actions IAM role
#
# This attachment grants the GitHub Actions role permissions
# required to run terraform init / plan / apply using remote backend
##############################

resource "aws_iam_role_policy_attachment" "github_actions_terraform_backend_attach" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_terraform_backend.arn
}
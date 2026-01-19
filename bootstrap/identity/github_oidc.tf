##############################################
# GitHub Actions OIDC provider
#
# Registers GitHub as a trusted OIDC identity
# provider in AWS. This allows GitHub Actions
# workflows to authenticate in AWS without
# static credentials.
##############################################
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]

  tags = {
    Name      = "github-actions-oidc-provider"
    ManagedBy = "Terraform"
    Purpose   = "Allows GitHub Actions workflows to authenticate in AWS using OIDC without static credentials"
  }

}
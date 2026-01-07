# ─────────────────────────────────────────────
# SSO instance (load existing)
# ─────────────────────────────────────────────
data "aws_ssoadmin_instances" "sso" {}

locals {
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso.identity_store_ids)[0]
  instance_arn      = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
}

# ─────────────────────────────────────────────
# Identity: user + groups
# ─────────────────────────────────────────────
resource "aws_identitystore_group" "admin" {
  identity_store_id = local.identity_store_id
  display_name      = "Admin"
}

resource "aws_identitystore_group" "developer" {
  identity_store_id = local.identity_store_id
  display_name      = "Developer"
}

resource "aws_identitystore_group" "cicd" {
  identity_store_id = local.identity_store_id
  display_name      = "CICD"
}

resource "aws_identitystore_user" "denys" {
  identity_store_id = local.identity_store_id
  user_name         = var.admin_user_name
  display_name      = var.admin_user_name

  name {
    given_name  = var.admin_user_name
    family_name = var.project_name
  }

  emails {
    value   = var.admin_email
    type    = "work"
    primary = true
  }
}

# Add user to groups
resource "aws_identitystore_group_membership" "admin_member" {
  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.admin.group_id
  member_id         = aws_identitystore_user.denys.user_id
}

resource "aws_identitystore_group_membership" "developer_member" {
  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.developer.group_id
  member_id         = aws_identitystore_user.denys.user_id
}

resource "aws_identitystore_group_membership" "cicd_member" {
  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.cicd.group_id
  member_id         = aws_identitystore_user.denys.user_id
}

# ─────────────────────────────────────────────
# AWS Accounts
# ─────────────────────────────────────────────
locals {
  accounts = {
    cloudlab = var.accounts.main
  }
}

# ─────────────────────────────────────────────
# Permission Sets
# ─────────────────────────────────────────────

# Admin role
resource "aws_ssoadmin_permission_set" "admin" {
  name             = "Admin"
  instance_arn     = local.instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "admin_attach" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_ssoadmin_account_assignment" "admin_assign" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
  principal_id       = aws_identitystore_group.admin.group_id
  principal_type     = "GROUP"
  target_id          = local.accounts.cloudlab
  target_type        = "AWS_ACCOUNT"
}

# Developer role
resource "aws_ssoadmin_permission_set" "developer" {
  name             = "Developer"
  instance_arn     = local.instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "dev_lambda" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "dev_s3" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "dev_cloudwatch" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "dev_dynamodb" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "dev_eventbridge" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess"
}

resource "aws_ssoadmin_account_assignment" "dev_assign" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer.arn
  principal_id       = aws_identitystore_group.developer.group_id
  principal_type     = "GROUP"
  target_id          = local.accounts.cloudlab
  target_type        = "AWS_ACCOUNT"
}

# CICD role
resource "aws_ssoadmin_permission_set" "cicd" {
  name             = "CICD"
  instance_arn     = local.instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "cicd_cloudformation" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.cicd.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AWSCloudFormationFullAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "cicd_lambda" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.cicd.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "cicd_ecr" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.cicd.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_ssoadmin_account_assignment" "cicd_assign" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.cicd.arn
  principal_id       = aws_identitystore_group.cicd.group_id
  principal_type     = "GROUP"
  target_id          = local.accounts.cloudlab
  target_type        = "AWS_ACCOUNT"
}

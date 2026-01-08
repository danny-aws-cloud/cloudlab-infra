module "identity" {
  source = "./identity"

  admin_user_name = var.admin_user_name
  #admin_email     = var.admin_email
  main_account_id = var.main_account_id
  project_name    = var.project_name
}

module "ecr" {
  source = "./storage/ecr"
}
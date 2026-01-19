terraform {
  required_version = ">= 1.9.0"

  backend "s3" {
    bucket         = "cloudlab-terraform-state-889818959918"
    key            = "runtime/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "cloudlab-terraform-locks"
    encrypt        = true
  }
}

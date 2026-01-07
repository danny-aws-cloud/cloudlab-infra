resource "aws_ecr_repository" "cloudlab_api" {
  name = "cloudlab-api"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Project = "CloudLab"
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment_name}"
  tags = {
    Project     = var.project_name
    Environment = var.environment_name
  }
}
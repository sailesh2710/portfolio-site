# ------- S3 bucket for CodeBuild cache -------

resource "aws_s3_bucket" "build_artifacts" {
  bucket = "${local.name_prefix}-build-artifacts"
  tags   = local.tags
}

# ------- IAM role for CodeBuild -------

data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild_role" {
  name               = "${local.name_prefix}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

data "aws_iam_policy_document" "codebuild_policy" {
  # allow build cache + pipeline artifacts buckets
  statement {
    effect = "Allow"
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.build_artifacts.arn,
      "${aws_s3_bucket.build_artifacts.arn}/*",
      aws_s3_bucket.pipeline_artifacts.arn,
      "${aws_s3_bucket.pipeline_artifacts.arn}/*",
    ]
  }

  # allow CloudWatch Logs (optional but useful)
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codebuild_policy" {
  role   = aws_iam_role.codebuild_role.name
  policy = data.aws_iam_policy_document.codebuild_policy.json
}

# ------- CodeBuild project -------

resource "aws_codebuild_project" "build" {
  name        = "${local.name_prefix}-build"
  description = "Build Angular SSR app for ${local.name_prefix}"

  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = 10

  # We let CodePipeline feed the source & take the artifact
  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"  # uses your existing file at repo root
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.build_artifacts.bucket
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0" # supports Node 20
    type         = "LINUX_CONTAINER"
  }

  tags = local.tags
}
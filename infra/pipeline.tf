resource "aws_codepipeline" "portfolio_pipeline" {
  name     = "portfolio-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.artifact_bucket.bucket
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = 1

      output_artifacts = ["SourceOutput"]

      configuration = {
        Owner = "sailesh2710"
        Repo  = "portfolio-site"
        Branch     = "main"
        OAuthToken = var.github_token
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]
      version          = 1

      configuration = {
        ProjectName = aws_codebuild_project.portfolio_build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name             = "Deploy"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "ElasticBeanstalk"
      input_artifacts  = ["BuildOutput"]
      version          = 1

      configuration = {
        ApplicationName = aws_elastic_beanstalk_application.portfolio_app.name
        EnvironmentName = aws_elastic_beanstalk_environment.portfolio_env.name
      }
    }
  }
}

resource "aws_codebuild_project" "portfolio_build" {
  name         = "portfolio-build"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:6.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
    environment_variable {
      name  = "ENV"
      value = "prod"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  cache {
    type = "LOCAL"
    modes = ["LOCAL_SOURCE_CACHE"]
  }
}

resource "aws_iam_role_policy" "codepipeline_s3_policy" {
  name = "codepipeline-s3-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListAllMyBuckets"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          aws_s3_bucket.artifact_bucket.arn,
          "${aws_s3_bucket.artifact_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_codebuild_access" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
}

resource "aws_iam_role_policy_attachment" "codepipeline_s3_access" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "codebuild_cloudwatch_logs" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}
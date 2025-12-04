resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "sailesh-artifact-bucket-${random_id.bucket_suffix.hex}"

  force_destroy = true

  tags = {
    Name = "PortfolioPipelineArtifactBucket"
    Project = "PortfolioCI-CD"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_iam_role" "codepipeline_role" {
  name = "portfolio-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codepipeline.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy_attachment" "codepipeline_policy_attach" {
  name       = "codepipeline-default-policy-attach"
  roles      = [aws_iam_role.codepipeline_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}

resource "aws_iam_role" "codebuild_role" {
  name = "portfolio-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "codebuild.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_basic" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
}

resource "aws_iam_role_policy_attachment" "codebuild_s3_access" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
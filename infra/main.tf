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

# Elastic Beanstalk service role
resource "aws_iam_role" "eb_service_role" {
  name = "aws-elasticbeanstalk-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "elasticbeanstalk.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eb_service_role_attach" {
  role       = aws_iam_role.eb_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

# EC2 instance profile for EB
resource "aws_iam_role" "eb_ec2_role" {
  name = "aws-elasticbeanstalk-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eb_ec2_role_attach" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = "aws-elasticbeanstalk-ec2-role"
  role = aws_iam_role.eb_ec2_role.name
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
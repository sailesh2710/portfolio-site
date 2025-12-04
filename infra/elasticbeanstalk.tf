# ---------------------------------------
# Elastic Beanstalk Service & EC2 Roles
# ---------------------------------------

# EB Service Role
resource "aws_iam_role" "eb_service_role" {
  name = "aws-elasticbeanstalk-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "eb_service_role_extra" {
  name = "eb-service-extra-permissions"
  role = aws_iam_role.eb_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeImages",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeKeyPairs",
          "ec2:DescribePlacementGroups"
        ]
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "eb_service_role_managed2" {
  role       = aws_iam_role.eb_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

# EB EC2 Instance Role
resource "aws_iam_role" "eb_ec2_role" {
  name = "aws-elasticbeanstalk-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "eb_ec2_role_managed2" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = "aws-elasticbeanstalk-ec2-role"
  role = aws_iam_role.eb_ec2_role.name
}

# ---------------------------------------
# Elastic Beanstalk Application
# ---------------------------------------
resource "aws_elastic_beanstalk_application" "portfolio_app" {
  name        = "portfolio-app"
  description = "Elastic Beanstalk app for Sailesh’s Portfolio CI/CD deployment"
}

# ---------------------------------------
# Elastic Beanstalk Environment
# ---------------------------------------
resource "aws_elastic_beanstalk_environment" "portfolio_env" {
  name                = "portfolio-env"
  application         = aws_elastic_beanstalk_application.portfolio_app.name
  platform_arn = "arn:aws:elasticbeanstalk:us-west-2::platform/Node.js 20 running on 64bit Amazon Linux 2023/6.7.0"

  # EB Service Role
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.eb_service_role.name
  }

  # EB EC2 Instance Profile
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }

  # ---------------------------------------
  # Auto Scaling + Instance Type Settings
  # ---------------------------------------
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.micro"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "3"
  }

  # Load balanced environment
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  # ---------------------------------------
  # Auto Scaling Trigger (CPU-based)
  # ---------------------------------------
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "MeasureName"
    value     = "CPUUtilization"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Unit"
    value     = "Percent"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperThreshold"
    value     = "60"    # Scale out above 60%
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerThreshold"
    value     = "20"    # Scale in below 20%
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Period"
    value     = "60"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "EvaluationPeriods"
    value     = "3"
  }

  lifecycle {
    ignore_changes = [setting]   # Prevents terraform drift when EB updates internal settings
  }
}

# Extra IAM policy so CodePipeline can deploy to Elastic Beanstalk
resource "aws_iam_policy" "codepipeline_eb_policy" {
  name        = "portfolio-codepipeline-eb-policy"
  description = "Allow CodePipeline to create EB application versions and update environment"

  policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Action = [
        "cloudformation:DescribeStacks",
        "cloudformation:DescribeStackResource",
        "cloudformation:DescribeStackEvents",
        "cloudformation:GetTemplate",
        "cloudformation:UpdateStack",
        "cloudformation:CreateChangeSet",
        "cloudformation:DescribeChangeSet",
        "cloudformation:ExecuteChangeSet"
      ]
      Resource = "*"
    },
    {
      Effect = "Allow"
      Action = [
        "elasticbeanstalk:*",
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ]
      Resource = "*"
    },
    {
      Effect = "Allow"
      Action = [
        "autoscaling:UpdateAutoScalingGroup",
        "autoscaling:CreateAutoScalingGroup",
        "autoscaling:PutScalingPolicy",
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribePolicies",
        "autoscaling:DescribeScalingActivities",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:CreateLaunchConfiguration",
        "autoscaling:DeleteLaunchConfiguration",
        "autoscaling:CreateOrUpdateTags",
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:CreateLaunchTemplate",
        "ec2:CreateLaunchTemplateVersion",
        "ec2:ModifyLaunchTemplate",
        "ec2:DeleteLaunchTemplate",
        "ec2:DescribeLaunchTemplates",
        "ec2:DescribeLaunchTemplateVersions",
        "ec2:GetLaunchTemplateData",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeImages",
        "ec2:DescribeAccountAttributes",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateTags",
        "ec2:DescribeKeyPairs",
        "ec2:DescribePlacementGroups"
      ]
      Resource = "*"
    }
  ]
})
}

resource "aws_iam_role_policy_attachment" "codepipeline_eb_policy_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_eb_policy.arn
}


resource "aws_iam_role_policy_attachment" "artifact_bucket_attach_pipeline" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.artifact_bucket_access.arn
}

resource "aws_iam_role_policy_attachment" "artifact_bucket_attach_codebuild" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.artifact_bucket_access.arn
}

resource "aws_iam_policy" "kms_artifact_access" {
  name = "portfolio-kms-artifact-access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kms_access_pipeline" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.kms_artifact_access.arn
}

resource "aws_iam_role_policy_attachment" "kms_access_codebuild" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.kms_artifact_access.arn
}

# Policy to allow CodePipeline + CodeBuild to access artifact bucket
resource "aws_iam_policy" "artifact_bucket_access" {
  name        = "portfolio-artifact-bucket-access"
  description = "Allows access to the S3 artifact bucket for builds and deployments"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      }
    ]
  })
}

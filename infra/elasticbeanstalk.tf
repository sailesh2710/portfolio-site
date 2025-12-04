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
    value     = "aws-elasticbeanstalk-service-role"
  }

  # EB EC2 Instance Profile
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role"
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
          "elasticbeanstalk:CreateApplicationVersion",
          "elasticbeanstalk:DescribeApplicationVersions",
          "elasticbeanstalk:DescribeEnvironments",
          "elasticbeanstalk:UpdateEnvironment"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        # Let EB pull the build artifact from your artifact bucket
        Resource = "${aws_s3_bucket.artifact_bucket.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudformation:GetTemplate",
          "cloudformation:DescribeStacks",
          "cloudformation:DescribeStackResources",
          "cloudformation:ListStackResources"
        ]
        # Allow CodePipeline to read the Elastic Beanstalk backing CloudFormation stacks
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "codepipeline_eb_policy_attach" {
  name       = "codepipeline-eb-policy-attach"
  roles      = [aws_iam_role.codepipeline_role.name]
  policy_arn = aws_iam_policy.codepipeline_eb_policy.arn
}
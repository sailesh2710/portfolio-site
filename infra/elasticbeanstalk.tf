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
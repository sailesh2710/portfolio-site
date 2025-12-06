# -------------------------------------------------------
# IAM ROLE + INSTANCE PROFILE FOR ELASTIC BEANSTALK EC2
# -------------------------------------------------------

data "aws_iam_policy" "eb_web_tier" {
  arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role" "eb_ec2_role" {
  name = "${local.name_prefix}-eb-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eb_ec2_web_tier" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = data.aws_iam_policy.eb_web_tier.arn
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "${local.name_prefix}-eb-ec2-profile"
  role = aws_iam_role.eb_ec2_role.name
}

# -------------------------------------------------------
# NETWORKING (DEFAULT VPC + SUBNETS + SECURITY GROUP)
# -------------------------------------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "eb_instances" {
  name        = "${local.name_prefix}-eb-sg"
  description = "Security group for EB instances"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# -------------------------------------------------------
# ELASTIC BEANSTALK APPLICATION
# -------------------------------------------------------

resource "aws_elastic_beanstalk_application" "app" {
  name        = "${local.name_prefix}-app"
  description = "Elastic Beanstalk app for ${var.project_name}"
  tags        = local.tags
}

# -------------------------------------------------------
# ELASTIC BEANSTALK ENVIRONMENT (SINGLE INSTANCE)
# -------------------------------------------------------

resource "aws_elastic_beanstalk_environment" "env" {
  name                = "${local.name_prefix}-env"
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = var.eb_solution_stack

  # Single Instance Environment
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }

  # EC2 Instance Profile
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }

  # Instance Type
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }

  # VPC ID
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = data.aws_vpc.default.id
  }

  # Subnets
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", data.aws_subnets.default.ids)
  }

  # Public IP for EC2
  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "true"
  }

  # Security Group assignment
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.eb_instances.id
  }

  # -------------------------------
  # AUTO SCALING CONFIGURATION
  # -------------------------------
  # Switch environment type to LoadBalanced for scaling
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  # Auto Scaling Group size
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

  # Scaling Trigger - Request Count
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "MeasureName"
    value     = "RequestCount"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Statistic"
    value     = "Sum"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Unit"
    value     = "Count"
  }

  # Threshold (e.g., if > 1000 requests in 1 minute)
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperThreshold"
    value     = "300"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerThreshold"
    value     = "100"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Period"
    value     = "30"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "EvaluationPeriods"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "BreachDuration"
    value     = "10"
  }

  # ============================
  # CloudWatch Logs Streaming
  # ============================
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = "14"
  }

  # Ensure enhanced health is enabled
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "project_name" {
  description = "Base project name (used as prefix for resources)"
  type        = string
}

variable "environment_name" {
  description = "Logical environment name (e.g. dev, prod)"
  type        = string
}

variable "eb_solution_stack" {
  description = "Elastic Beanstalk solution stack name (Node.js platform)"
  type        = string
}

variable "github_owner" {
  description = "GitHub user or org that owns the repo"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without owner)"
  type        = string
}

variable "github_branch" {
  description = "Branch to build/deploy from"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Beanstalk"
  type        = string
  default     = "t3.micro"
}
output "elastic_beanstalk_url" {
  description = "Public URL of the Elastic Beanstalk environment"
  value       = "http://${aws_elastic_beanstalk_environment.env.cname}"
}

output "codepipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.pipeline.name
}

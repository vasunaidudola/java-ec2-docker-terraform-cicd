variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "us-east-1"
}

variable "dockerhub_username" {
  type        = string
  description = "Docker Hub username"
}

variable "image_name" {
  type        = string
  description = "Docker image name"
  default     = "java-ec2-demo"
}

variable "image_tag" {
  type        = string
  description = "Docker image tag"
  default     = "latest"
}

# New variable to force redeploy when code changes
variable "deploy_version" {
  type        = string
  description = "Forces EC2 replacement when app version changes"
  default     = ""
}

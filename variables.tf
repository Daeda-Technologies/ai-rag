# AWS region
variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

# VPC CIDR
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Subnet CIDR
variable "sagemaker_subnet_cidr" {
  description = "CIDR block for the SageMaker subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# Availability zone
variable "availability_zone" {
  description = "Availability zone for the subnets"
  type        = string
  default     = "us-west-2a"
}

# S3 Bucket Name
variable "s3_bucket_name" {
  description = "Name of the S3 bucket to store the model data"
  type        = string
}

# SageMaker Execution Role Name
variable "sagemaker_execution_role_name" {
  description = "Name of the IAM role that SageMaker will use"
  type        = string
  default     = "sagemaker-execution-role"
}

# SageMaker Model Name
variable "sagemaker_model_name" {
  description = "Name of the SageMaker model for LLM inference"
  type        = string
}

# LLM Inference Image
variable "llm_inference_image" {
  description = "Container image for LLM inference"
  type        = string
}

# Model Data URL in S3
variable "model_data_url" {
  description = "S3 URL for the model data"
  type        = string
}

# Endpoint Configuration Name
variable "endpoint_config_name" {
  description = "SageMaker Endpoint Configuration Name"
  type        = string
}

# Endpoint Name
variable "endpoint_name" {
  description = "SageMaker Endpoint Name"
  type        = string
}

# Initial Instance Count
variable "initial_instance_count" {
  description = "Initial number of instances for the endpoint"
  type        = number
  default     = 1
}

# Max Capacity for Scaling
variable "max_capacity" {
  description = "Maximum number of instances for auto-scaling"
  type        = number
  default     = 5
}

# Min Capacity for Scaling
variable "min_capacity" {
  description = "Minimum number of instances for auto-scaling"
  type        = number
  default     = 1
}

# Instance Type for Inference
variable "instance_type" {
  description = "Type of instance to use for SageMaker inference"
  type        = string
  default     = "ml.m5.xlarge"
}


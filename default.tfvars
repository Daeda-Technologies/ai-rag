# ------------------------
# AWS / Networking Config
# ------------------------

aws_region              = "us-west-2"
vpc_cidr                = "10.0.0.0/16"
sagemaker_subnet_cidr   = "10.0.1.0/24"
availability_zone       = "us-west-2a"

# ------------------------
# S3 Bucket (Model + Docs)
# ------------------------

s3_bucket_name          = "my-llm-inference-bucket"  # For model artifacts
# Note: rag_docs bucket will auto-generate a suffix to avoid name collisions

# ------------------------
# SageMaker Configuration
# ------------------------

sagemaker_execution_role_name = "my-sagemaker-execution-role"
sagemaker_model_name          = "my-llm-inference-model"
llm_inference_image           = "123456789012.dkr.ecr.us-west-2.amazonaws.com/my-llm-inference:latest"
model_data_url                = "s3://daedatechnologies-public/model.tar.gz"
endpoint_config_name          = "my-llm-inference-endpoint-config"
endpoint_name                 = "my-llm-inference-endpoint"

initial_instance_count        = 1
instance_type                 = "ml.m5.xlarge"
max_capacity                  = 5
min_capacity                  = 1

ecr_repository_name           = "huggingface-pytorch-inference"

# ------------------------
# Lambda Function Config
# ------------------------

lambda_function_name          = "rag_query"
lambda_memory_size            = 512
lambda_timeout                = 30
lambda_runtime                = "python3.11"
lambda_handler                = "rag_query.handler"
lambda_zip_path               = "rag_query.zip"

# ------------------------
# API Gateway Config
# ------------------------

api_gateway_name              = "rag_query"
api_stage_name                = "prod"

# ------------------------
# Domain & SSL Config
# ------------------------

domain_name                = "api.daedacloud.com"
hosted_zone_name           = "daedacloud.com"

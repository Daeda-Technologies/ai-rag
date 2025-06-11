# ACM certificate request in us-east-1 for custom domain
provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
}

# Data source for the hosted zone
data "aws_route53_zone" "hosted" {
  name = var.hosted_zone_name
}

# ACM certificate for API Gateway custom domain
resource "aws_acm_certificate" "cert" {
  provider          = aws.useast1
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  name    = aws_acm_certificate.cert.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.cert.domain_validation_options[0].resource_record_type
  zone_id = data.aws_route53_zone.hosted.id
  records = [aws_acm_certificate.cert.domain_validation_options[0].resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.useast1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}
# Specify the AWS provider and region
provider "aws" {
  region = var.aws_region
}

# VPC creation
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

# Subnet creation for SageMaker and Lambda
resource "aws_subnet" "sagemaker_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.sagemaker_subnet_cidr
  availability_zone = var.availability_zone
}

# Security group for SageMaker endpoint
resource "aws_security_group" "sagemaker_security_group" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# S3 Bucket for Model Artifacts and Input Data
resource "aws_s3_bucket" "sagemaker_model_data_bucket" {
  bucket = var.s3_bucket_name
}

# IAM Role for SageMaker to access S3 and execute jobs
resource "aws_iam_role" "sagemaker_execution_role" {
  name = var.sagemaker_execution_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "sagemaker.amazonaws.com"
        },
      },
    ],
  })
}

# Attach policy to allow access to S3 and CloudWatch
resource "aws_iam_role_policy" "sagemaker_access_policy" {
  name   = "sagemaker-access-policy"
  role   = aws_iam_role.sagemaker_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Effect   = "Allow",
        Resource = [
          aws_s3_bucket.sagemaker_model_data_bucket.arn,
          "${aws_s3_bucket.sagemaker_model_data_bucket.arn}/*"
        ]
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ],
  })
}

# SageMaker Model for LLM Inference
resource "aws_sagemaker_model" "sagemaker_llm_model" {
  name          = var.sagemaker_model_name
  execution_role_arn = aws_iam_role.sagemaker_execution_role.arn

  primary_container {
    image           = var.llm_inference_image
    model_data_url  = var.model_data_url
  }

  vpc_config {
    security_group_ids = [aws_security_group.sagemaker_security_group.id]
    subnets            = [aws_subnet.sagemaker_subnet.id]
  }
}

# SageMaker Endpoint Configuration with Auto Scaling
resource "aws_sagemaker_endpoint_configuration" "llm_endpoint_config" {
  name = var.endpoint_config_name

  production_variants {
    model_name           = aws_sagemaker_model.sagemaker_llm_model.name
    variant_name         = "variant-1"
    initial_instance_count = var.initial_instance_count
    instance_type        = var.instance_type
    initial_variant_weight = 1.0
  }
}

# SageMaker Endpoint for LLM Inference
resource "aws_sagemaker_endpoint" "llm_endpoint" {
  endpoint_name          = var.endpoint_name
  endpoint_config_name   = aws_sagemaker_endpoint_configuration.llm_endpoint_config.name
}

# Auto Scaling Target for SageMaker Endpoint
resource "aws_appautoscaling_target" "llm_scaling_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "endpoint/${aws_sagemaker_endpoint.llm_endpoint.id}/variant/variant-1"
  scalable_dimension = "sagemaker:variant:DesiredInstanceCount"
  service_namespace  = "sagemaker"
}

# Auto Scaling Policy to Scale Up
resource "aws_appautoscaling_policy" "scale_up_policy" {
  name               = "scale-up-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.llm_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.llm_scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.llm_scaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 70.0  # Target utilization (adjust based on metrics)
    predefined_metric_specification {
      predefined_metric_type = "SageMakerVariantInvocationsPerInstance"
    }
    scale_in_cooldown  = 300  # Cooldown period before scaling in
    scale_out_cooldown = 300  # Cooldown period before scaling out
  }
}

# Auto Scaling Policy to Scale Down
resource "aws_appautoscaling_policy" "scale_down_policy" {
  name               = "scale-down-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.llm_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.llm_scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.llm_scaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 30.0  # Target utilization for scaling down
    predefined_metric_specification {
      predefined_metric_type = "SageMakerVariantInvocationsPerInstance"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# Outputs
output "sagemaker_llm_endpoint_name" {
  description = "The name of the SageMaker LLM inference endpoint"
  value       = aws_sagemaker_endpoint.llm_endpoint.endpoint_name
}


resource "aws_api_gateway_rest_api" "rag_query" {
  name        = var.api_gateway_name
  description = "API Gateway for RAG Lambda functions"
}

resource "aws_api_gateway_domain_name" "custom" {
  domain_name     = var.domain_name
  certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
}

resource "aws_api_gateway_base_path_mapping" "custom" {
  domain_name = aws_api_gateway_domain_name.custom.domain_name
  rest_api_id = aws_api_gateway_rest_api.rag_query.id
  stage_name  = var.api_stage_name
}

resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.hosted.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.custom.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.custom.cloudfront_zone_id
    evaluate_target_health = false
  }
}
resource "aws_api_gateway_resource" "rag_resource" {
  rest_api_id = aws_api_gateway_rest_api.rag_query.id
  parent_id   = aws_api_gateway_rest_api.rag_query.root_resource_id
  path_part   = "rag"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.rag_query.id
  resource_id   = aws_api_gateway_resource.rag_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.rag_query.id
  resource_id = aws_api_gateway_resource.rag_resource.id
  http_method = aws_api_gateway_method.post_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.rag_query.invoke_arn
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rag_query.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rag_query.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.rag_query.id
  stage_name  = var.api_stage_name
}

resource "aws_lambda_function" "rag_query" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_exec.arn
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  filename      = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size
  vpc_config {
    subnet_ids         = [aws_subnet.sagemaker_subnet.id]
    security_group_ids = [aws_security_group.sagemaker_security_group.id]
  }
  environment {
    variables = {
      STAGE = var.api_stage_name
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "rag-lambda-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_s3_bucket" "rag_docs" {
  bucket = "rag-docs-${random_id.suffix.hex}"
  force_destroy = true
}

resource "random_id" "suffix" {
  byte_length = 4
}

# Public subnet for NAT
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc = true
}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  depends_on    = [aws_internet_gateway.igw]
}

# Route Table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

# Route Table for private (SageMaker) subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.sagemaker_subnet.id
  route_table_id = aws_route_table.private.id
}
# ECR repository for LLM inference images
resource "aws_ecr_repository" "llm_inference_repo" {
  name = var.llm_inference_repo_name
}
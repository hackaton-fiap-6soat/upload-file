terraform {
  backend "s3" {
    bucket = "upload-file"
    key    = "lambda.tfstate"
    region = "us-east-1"
  }
}

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

variable "lambda_role_name" {
  description = "Lambda handler"
  type        = string
  default     = "lambda_execution_role"
}

variable "sqs" {
  description = "Nome da fila SQS"
  type        = string
  default     = "fila-processamento-arquivos"
}

variable "bucket" {
  description = "Nome do bucket S3"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = contains(["us-east-1", "us-west-1", "eu-west-1"], var.region)
    error_message = "Região inválida. Use us-east-1, us-west-1 ou eu-west-1."
  }
}

# Provedor AWS
provider "aws" {
  region = var.region
  profile = "default"
}

# Definindo os recursos S3, SQS e IAM

resource "aws_s3_bucket" "file_upload" {
  bucket = var.bucket
  force_destroy = true
}

# VPC
data "aws_vpc" "hackathon-vpc" {
  filter {
    name   = "tag:Name"
    values = ["fiap-hackathon-vpc"]
  }
}

data "aws_subnets" "private-subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.hackathon-vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

resource "aws_security_group" "lambda" {
  name        = "upload-lambda-sg"
  description = "Security group for Lambda"
  vpc_id      = data.aws_vpc.hackathon-vpc.id # data source da vpc

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"] # data source da vpc
  }
}




# Definindo a função Lambda

# Package the Lambda function
data "archive_file" "file_upload_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../src"
  output_path = "${path.module}/../file_upload.zip"
}

resource "aws_lambda_function" "file_upload_lambda" {
  filename      = "${path.module}/../file_upload.zip"
  source_code_hash = data.archive_file.file_upload_lambda.output_base64sha256
  function_name = "file_upload_lambda"
  role          = data.aws_iam_role.lab_role.arn
  handler       = "app.controllers.lambda_handler.lambda_handler"
  runtime       = "python3.8"

  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.file_upload.bucket
      SQS_URL = var.sqs
    }
  }

  vpc_config {
    subnet_ids         = data.aws_subnets.private-subnets.ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  depends_on = [ data.archive_file.file_upload_lambda ]
}

# API Gateway
# Data sources para buscar a api criada por este repositório com o nome de "api_gw_api"
data aws_apigatewayv2_apis apis {
  name = "api_gw_api"
}
data aws_apigatewayv2_api api {
  api_id = one(data.aws_apigatewayv2_apis.apis.ids)
}

resource "aws_apigatewayv2_integration" "upload_lambda_integration" {
  api_id             = data.aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.file_upload_lambda.invoke_arn
  payload_format_version = "2.0"
}

## Data sources para buscar o user pool criado por este repositório com o nome de "user-pool"

data aws_cognito_user_pools user_pools {
  name = "user-pool"
}
## Use the first user pool from the query
data aws_cognito_user_pool user_pool {
  user_pool_id = data.aws_cognito_user_pools.user_pools.ids[0]
}

data aws_cognito_user_pool_clients user_pool_clients {
  user_pool_id = data.aws_cognito_user_pool.user_pool.id
}

data aws_cognito_user_pool_client user_pool_client {
  user_pool_id = data.aws_cognito_user_pool.user_pool.id
  client_id = data.aws_cognito_user_pool_clients.user_pool_clients.client_ids[0]
}

data "aws_region" "current" {}

resource "aws_apigatewayv2_authorizer" "cognito_authorizer" {
  api_id = data.aws_apigatewayv2_api.api.id
  name = "cognito_authorizer"
  authorizer_type = "JWT"
  identity_sources = ["$request.header.Authorization"]
  jwt_configuration {
    issuer = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${data.aws_cognito_user_pool.user_pool.id}"
    audience = [data.aws_cognito_user_pool_client.user_pool_client.id]
  }
}

resource "aws_apigatewayv2_route" "upload_lambda_api_route" {
  api_id    = data.aws_apigatewayv2_api.api.id
  route_key = "ANY /upload"
  target    = "integrations/${aws_apigatewayv2_integration.upload_lambda_integration.id}"
  authorization_type = "JWT"
  authorizer_id = aws_apigatewayv2_authorizer.cognito_authorizer.id
}

resource "aws_lambda_permission" "upload_lambda_allow_apigateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.file_upload_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${data.aws_apigatewayv2_api.api.execution_arn}/*"
}

output "lambda_function_name" {
  value       = aws_lambda_function.file_upload_lambda.function_name
  description = "Nome da função Lambda"
}



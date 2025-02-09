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

resource "aws_sqs_queue" "file_processing_queue" {
  name = var.sqs
}

# resource "aws_iam_role" "lambda_role" {
#   name = var.lambda_role_name

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action    = "sts:AssumeRole"
#         Effect    = "Allow"
#         Principal = {
#           Service = "lambda.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_policy" "lambda_policy" {
#   name        = "lambda_s3_sqs_policy"
#   description = "Permissões para o Lambda acessar S3 e SQS"
#   policy      = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action   = [
#           "s3:PutObject",
#           "s3:GetObject",
#           "s3:ListBucket"
#         ]
#         Effect   = "Allow"
#         Resource = [
#           "arn:aws:s3:::${aws_s3_bucket.file_upload.bucket}/*",
#           "arn:aws:s3:::${aws_s3_bucket.file_upload.bucket}"
#         ]
#       },
#       {
#         Action   = "sqs:SendMessage"
#         Effect   = "Allow"
#         Resource = aws_sqs_queue.file_processing_queue.arn
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
#   policy_arn = aws_iam_policy.lambda_policy.arn
#   role       = aws_iam_role.lambda_role.name
# }

# Definindo a função Lambda

resource "aws_lambda_function" "file_upload_lambda" {
  function_name = "file_upload_lambda"
  role          = data.aws_iam_role.lab_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  filename      = "lambda.zip"

  environment {
    variables = {
      INPUT_BUCKET = aws_s3_bucket.file_upload.bucket
      SQS_URL = aws_sqs_queue.file_processing_queue.id
    }
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "file_upload_api" {
  name        = "file_upload_api"
  description = "API para upload de arquivos"
}

resource "aws_api_gateway_resource" "upload_resource" {
  rest_api_id = aws_api_gateway_rest_api.file_upload_api.id
  parent_id   = aws_api_gateway_rest_api.file_upload_api.root_resource_id
  path_part   = "upload"
}

resource "aws_api_gateway_method" "upload_method" {
  rest_api_id   = aws_api_gateway_rest_api.file_upload_api.id
  resource_id   = aws_api_gateway_resource.upload_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.file_upload_api.id
  resource_id             = aws_api_gateway_resource.upload_resource.id
  http_method             = aws_api_gateway_method.upload_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.file_upload_lambda.arn}/invocations"
}

resource "aws_lambda_permission" "api_gateway_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.file_upload_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.file_upload_api.execution_arn}/*/*"
}

# Stage e Deployment do API Gateway
resource "aws_api_gateway_deployment" "deployment" {
  depends_on  = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.file_upload_api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.file_upload_api))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api_stage" {
  stage_name    = "dev"
  rest_api_id   = aws_api_gateway_rest_api.file_upload_api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
}

# Outputs
output "api_url" {
  value       = "https://${aws_api_gateway_rest_api.file_upload_api.id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.api_stage.stage_name}"
  description = "URL do API Gateway"
}

output "lambda_function_name" {
  value       = aws_lambda_function.file_upload_lambda.function_name
  description = "Nome da função Lambda"
}



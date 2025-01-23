resource "aws_lambda_function" "file_upload_lambda" {
  function_name = "file_upload_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"

  # Caminho para o arquivo zipado da sua função Lambda
  filename      = "lambda.zip"

  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.file_upload.bucket
      SQS_URL        = aws_sqs_queue.file_processing_queue.url
    }
  }
}

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
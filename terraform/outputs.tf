output "api_url" {
  value = aws_api_gateway_rest_api.file_upload_api.invoke_url
  description = "URL do API Gateway"
}

output "lambda_function_name" {
  value = aws_lambda_function.file_upload_lambda.function_name
  description = "Nome da função Lambda"
}
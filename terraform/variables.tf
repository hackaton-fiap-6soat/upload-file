variable "s3_bucket_name" {
  description = "Nome do bucket S3"
  type        = string
}

variable "sqs_queue_name" {
  description = "Nome da fila SQS"
  type        = string
}

variable "lambda_role_name" {
  description = "Nome da Role para a função Lambda"
  type        = string
}
output "lambda_role_arn" {
  value       = aws_iam_role.default.arn
  description = "ARN of the execution role used by Lambda"
}

output "function_name" {
  value       = aws_lambda_function.default.function_name
  description = "Name of the Lambda function"
}
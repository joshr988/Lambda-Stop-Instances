variable "function_name" {
  type        = string
  description = "Name of the Lambda function"
}

variable "function_description" {
  type        = string
  description = "Description for the Lambda function"
  default     = null
}

variable "function_dir" {
  type        = string
  description = "Directory relative to the location where `terraform commands` are being run"
}

variable "handler" {
  type        = string
  description = "Name of the Lambda handler, in the format <filename>.<python function name>"
}

variable "timeout" {
  type        = number
  description = "Timeout in seconds"
  default     = 300
}

variable "runtime" {
  type        = string
  description = "Runtime to use"
  default     = "python3.8"
}

variable "environment_variables" {
  type        = map(string)
  description = "Map of environment variables"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Map of tags in the format `<Key> = <Value`"
  default     = null
}
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "api_endpoint" {
  description = "API endpoint for synthetic tests"
  type        = string
}

variable "datadog_api_key" {
  description = "DataDog API key"
  type        = string
  sensitive   = true
}

variable "datadog_app_key" {
  description = "DataDog application key"
  type        = string
  sensitive   = true
}

variable "budget_amount_usd" {
  description = "The budget amount in USD"
  type        = number
}

variable "budget_threshold_percentage" {
  description = "The percentage threshold for budget alerts (e.g., 80 for 80%)"
  type        = number
}

variable "budget_email" {
  description = "The email address to receive budget alerts"
  type        = string
}

variable "environment" {
  description = "The environment for which to create the resources (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "service" {
  description = "The service name for FinOps tagging"
  type        = string
  default     = "Massar"
}


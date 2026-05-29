
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


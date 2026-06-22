resource "aws_budgets_budget" "main" {
  name         = "monthly-budget"
  budget_type  = "COST"
  limit_amount = var.budget_amount_usd
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold_type             = "PERCENTAGE"
    threshold                  = var.budget_threshold_percentage
    subscriber_email_addresses = [var.budget_email]

  }
}


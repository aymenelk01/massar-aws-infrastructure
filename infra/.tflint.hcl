tflint {
  required_version = ">= 0.50"
}

config {
  call_module_type = "local"
}

plugin "aws" {
  enabled = true
  version = "0.47.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

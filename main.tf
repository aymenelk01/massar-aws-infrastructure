# call the vpc module
module "vpc" {
  source      = "./modules/vpc"
  environment = var.environment
  aws_region  = var.aws_region
}

# call the security module and pass the vpc id from the vpc module
module "security" {
  source      = "./modules/security"
  environment = var.environment
  vpc_id      = module.vpc.vpc_id

}

module "endpoints" {
  source                 = "./modules/endpoints"
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  vpc_endpoints_sg_id    = module.security.vpc_endpoints_sg_id
  aws_region             = var.aws_region
}

module "ecr" {
  source      = "./modules/ecr"
  environment = var.environment
}

module "cognito" {
  source      = "./modules/cognito"
  environment = var.environment
}

module "database" {
  source                 = "./modules/database"
  environment            = var.environment
  private_db_subnet_ids  = module.vpc.private_db_subnet_ids
  db_username           = var.db_username
  db_password           = var.db_password
  aurora_sg_id         = module.security.aurora_sg_id
  rdsproxy_sg_id       = module.security.rdsproxy_sg_id
}
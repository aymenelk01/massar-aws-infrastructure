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

module "cache" {
  source                 = "./modules/cache"
  environment            = var.environment
  private_db_subnet_ids  = module.vpc.private_db_subnet_ids
  elasticache_sg_id     = module.security.elasticache_sg_id
}

module "loadbalancer" {
  source = "./modules/loadbalancer"
  environment = var.environment
  vpc_id = module.vpc.vpc_id
  alb_sg_id = module.security.alb_sg_id
  public_subnet_ids = module.vpc.public_subnet_ids
  certificate_arn = var.certificate_arn
  logs_bucket_name = var.logs_bucket_name
}

module "ecs" {
  source = "./modules/ecs"
  environment = var.environment
  vpc_id = module.vpc.vpc_id
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  ecs_sg_id = module.security.ecs_sg_id
  target_group_arn = module.loadbalancer.target_group_arn
  user_pool_id = module.cognito.user_pool_id
  user_pool_client_id = module.cognito.user_pool_client_id
  elasticache_replication_group_endpoint = module.cache.elasticache_replication_group_endpoint
  rds_proxy_endpoint = module.database.rds_proxy_endpoint
  db_name = var.db_name
  ecr_repository_url = module.ecr.ecr_repository_url
  documents_bucket_name = var.documents_bucket_name
  aws_region = var.aws_region
}

module "storage" {
  source = "./modules/storage"
  environment = var.environment
  documents_bucket_name = var.documents_bucket_name
  static_bucket_name = var.static_bucket_name
  state_bucket_name = var.state_bucket_name
  logs_bucket_name = var.logs_bucket_name
  
}
variable "environment" {
  description = "The environment for the cache module"
  type        = string
}

variable "elasticache_sg_id" {
  description = "List of security group IDs for the ElastiCache cluster"
  type        = string

}


variable "private_db_subnet_ids" {
  description = "List of private database subnet IDs"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones for the ElastiCache cluster"
  type        = list(string)
  default     = ["eu-south-1a", "eu-south-1b"]
}
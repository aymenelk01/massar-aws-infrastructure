# variable of the the environment name
variable "environment" {
    description = "The environment name (e.g., dev, staging, prod)"
    type = string
}

# variable of the private db subnet 
variable "private_db_subnet_ids" {
    description = "List of private database subnet IDs"
    type = list(string)
}

# variable of the allocation storage for the RDS instance
variable "allocated_storage" {
    description = "The allocated storage for the RDS instance (in GB)"
    type = number
    default = 20
}

# variable of the database engine for the RDS instance
variable "db_engine" {
    description = "The database engine for the RDS instance (e.g., mysql, postgres)"
    type = string
    default = "mysql"
}

# variable of the instance class for the RDS instance
variable "instance_class" {
    description = "The instance class for the RDS instance (e.g., db.t3.micro)"
    type = string
    default = "db.t3.micro"
}

# variable of the database username for the RDS instance
variable "db_username" {
    description = "The database username for the RDS instance"
    type = string
}

# variable of the database password for the RDS instance
variable "db_password" {
    description = "The database password for the RDS instance"
    type = string
    sensitive = true
}

variable "rds_sg_id" {
    description = "The ID of the security group for the RDS instance"
    type = string
}

variable "rds_identifier" {
    description = "The identifier for the RDS instance"
    type = string
    default = "db-instance"
  
}
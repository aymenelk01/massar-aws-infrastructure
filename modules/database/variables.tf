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

variable "rdsproxy_sg_id" {
    description = "The ID of the security group for the RDS Proxy"
    type = string
}

variable "aurora_sg_id" {
    description = "The identifier for the Aurora cluster security group"
    type = string
  
}

variable "rdsproxy_sg_id" {
    description = "The identifier for the RDS Proxy security group"
    type = string
}


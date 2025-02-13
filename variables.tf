variable "environment" {
  description = "Deployment environment (e.g., dev, test, prod)"
  type        = string
}

variable "id" {
  description = "Unique identifier for naming resources"
  type        = string
}

variable "db_engine" {
  description = "The database engine"
  type        = string
  default     = "oracle-ee"
}

variable "db_instance_class" {
  description = "The instance class for the RDS instance"
  type        = string
  default     = "db.t3.small"
}

variable "db_name" {
  description = "The Oracle database name (SID/service name)"
  type        = string
}

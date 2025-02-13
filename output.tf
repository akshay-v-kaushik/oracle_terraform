output "db_instance_endpoint" {
  description = "The endpoint of the Oracle RDS instance."
  value       = aws_db_instance.oracle_db.address
}

output "db_instance_port" {
  description = "The port on which the Oracle RDS instance is listening."
  value       = aws_db_instance.oracle_db.port
}
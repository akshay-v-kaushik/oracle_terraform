
resource "random_password" "oracle_master_password" {
  length           = 16
  special          = true
  lower            = true
  upper            = true
  numeric          = true
  override_special = "!#$%^*"
}

resource "random_password" "read_user_password" {
  length  = 16
  special = true
}

resource "random_password" "rw_user_password" {
  length  = 16
  special = true
}

locals {
  # Construct the master username as <environment>_<id>_master
  master_username = "${var.environment}_${var.id}_master"
}

locals {
  read_username = "${var.environment}_read"
}

locals {
  rw_username = "${var.environment}_rw"
}

resource "aws_db_instance" "oracle_db" {
  allocated_storage      = 10
  engine                 = var.db_engine
  instance_class         = var.db_instance_class
  username               = local.master_username
  db_name = var.db_name
  password               = random_password.oracle_master_password.result
  parameter_group_name   = "default.oracle-ee-19"  
  db_subnet_group_name   = aws_db_subnet_group.avk_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.avk_db_sg.id]
  skip_final_snapshot    = true
  tags = {
    Environment = var.environment
    Name        = "${var.environment}_${var.id}_oracle_rds"
  }
}

resource "null_resource" "create_oracle_users" {
  depends_on = [aws_db_instance.oracle_db]

  triggers = {
    rds_endpoint  = aws_db_instance.oracle_db.endpoint
    read_password = random_password.read_user_password.result
    rw_password   = random_password.rw_user_password.result
  }

  provisioner "local-exec" {
    command = join(" ", [
      "sudo apt update &&",
      "sudo apt install python3-pip &&",
      "pip3 install cx_Oracle &&",
      "python3",
      "${path.module}/scripts/create_users.py",
      aws_db_instance.oracle_db.endpoint,
      aws_db_instance.oracle_db.port,
      local.master_username,
      random_password.oracle_master_password.result,
      var.db_name,
      local.read_username,
      random_password.read_user_password.result,
      local.rw_username,
      random_password.rw_user_password.result,
      var.environment
    ])
  }
}

resource "aws_secretsmanager_secret" "avk_master_secret" {
  name        = "${var.environment}_${var.id}_master_credentials"
  description = "Master credentials for the Oracle RDS instance"
  tags = {
    Environment = var.environment
    Role        = "ADMIN"
  }
}

resource "aws_secretsmanager_secret_version" "avk_master_secret_version" {
  secret_id = aws_secretsmanager_secret.avk_master_secret.id
  secret_string = jsonencode({
    instance_name = "${var.environment}_${var.id}_oracle_rds",                     
    endpoint      = aws_db_instance.oracle_db.address, 
    database_name = "${var.environment}_${var.id}_oracle_rds",                    
    port          = aws_db_instance.oracle_db.port,   
    username      = local.master_username,    
    password      = random_password.oracle_master_password.result
  })
}

resource "aws_secretsmanager_secret" "read_user_secret" {
  name        = "${var.environment}_read_user_credentials"
  description = "Credentials for the Read-Only user on the Oracle RDS instance"
  tags = {
    Environment = var.environment
    Role        = "READ_USER"
  }
}

resource "aws_secretsmanager_secret_version" "read_user_secret_version" {
  secret_id = aws_secretsmanager_secret.read_user_secret.id
  secret_string = jsonencode({
    username = local.read_username,
    password = random_password.read_user_password.result
  })
}

resource "aws_secretsmanager_secret" "rw_user_secret" {
  name        = "${var.environment}_rw_user_credentials"
  description = "Credentials for the Read-Write user on the Oracle RDS instance"
  tags = {
    Environment = var.environment
    Role        = "RW_USER"
  }
}

resource "aws_secretsmanager_secret_version" "rw_user_secret_version" {
  secret_id = aws_secretsmanager_secret.rw_user_secret.id
  secret_string = jsonencode({
    username = local.rw_username,
    password = random_password.rw_user_password.result
  })
}

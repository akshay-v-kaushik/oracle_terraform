
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

resource "random_password" "admin_user_password" {
  length  = 16
  special = true
}

locals {
  # Construct the master username as <environment>_<id>_master
  master_username = "${var.environment}_${var.id}_master"
}

locals {
  admin_username = "${var.environment}_admin"
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
      "python3",
      "${path.module}/scripts/create_users.py",
      aws_db_instance.oracle_db.endpoint,
      aws_db_instance.oracle_db.port,
      local.master_username,
      random_password.oracle_master_password.result,
      var.db_name,
      local.admin_username,
      random_password.admin_user_password.result,
      local.read_username,
      random_password.read_user_password.result,
      local.rw_username,
      random_password.rw_user_password.result,
      var.environment
    ])
  }
}


resource "aws_secretsmanager_secret" "AVK_testdb_credentials" {
  name        = "${var.environment}_${var.id}_oracle_credentials"
  description = "Combined credentials for Oracle RDS instance: master, admin, read, and read-write"
  tags = {
    Environment = var.environment
    Role        = "CREDENTIALS"
  }
}

resource "aws_secretsmanager_secret_version" "AVK_testdb_credentials_version" {
  secret_id = aws_secretsmanager_secret.combined_credentials.id
  secret_string = jsonencode({
    master = {
      username = local.master_username,
      password = random_password.oracle_master_password.result
    },
    admin = {
      username = local.admin_username,
      password = random_password.admin_user_password.result
    },
    read = {
      username = local.read_username,
      password = random_password.read_user_password.result
    },
    rw = {
      username = local.rw_username,
      password = random_password.rw_user_password.result
    }
  })
}

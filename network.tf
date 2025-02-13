resource "aws_vpc" "avk_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "avk-vpc"
  }
}

resource "aws_subnet" "avk_subnet-1" {
  vpc_id            = aws_vpc.avk_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-1a"
  tags = {
    Name = "avk-subnet"
  }
}
resource "aws_subnet" "avk_subnet-2" {
  vpc_id            = aws_vpc.avk_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-1b"
  tags = {
    Name = "avk-subnet"
  }
}

resource "aws_db_subnet_group" "avk_db_subnet_group" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = [aws_subnet.avk_subnet-1.id, aws_subnet.avk_subnet-2.id]
  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}

resource "aws_security_group" "avk_db_sg" {
  name        = "${var.environment}-db-sg"
  description = "Security group for Oracle RDS instance"
  vpc_id      = aws_vpc.avk_vpc.id

  ingress {
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-db-sg"
  }
}

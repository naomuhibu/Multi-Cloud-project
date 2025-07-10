# =============================================================================
# RDS DATABASE
# =============================================================================

resource "aws_db_subnet_group" "main" {
  name        = "yoobee-db-subnet-group"
  subnet_ids = [aws_subnet.private_2a_db.id, aws_subnet.private_2b_db.id]

  tags = {
    Name = "Yoobee DB subnet group"
  }
}

resource "aws_db_instance" "mysql" {
  identifier            = "database-1"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t4g.micro"
  allocated_storage     = 20
  storage_encrypted     = true

  db_name   = "wordpress"
  username  = var.db_username
  password  = var.db_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  multi_az              = true
  backup_retention_period = 7
  backup_window         = "03:00-04:00"
  maintenance_window    = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "database-1"
  }
}
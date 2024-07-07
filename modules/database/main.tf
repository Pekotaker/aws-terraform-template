module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = var.identifier

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine               = "postgres"
  engine_version       = "15"
  family               = "postgres15" # DB parameter group
  major_engine_version = "15"         # DB option group
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage

  db_name  = var.db_name
  username = var.username
  password = var.password
  port     = "5432"
  # DB network
  availability_zone      = var.availability_zone
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  subnet_ids             = var.subnet_ids
  publicly_accessible    = false


  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "14:00-17:00"



  manage_master_user_password = false
  storage_encrypted           = false
  # important
  # Database Deletion Protection
  deletion_protection = false
  skip_final_snapshot = true


  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]
  tags = {
    Terraform = "true"
  }
}

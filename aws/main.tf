resource "aws_s3_bucket" "mybucket" {
  bucket = "lead-distribution-app-bucket"
}
resource "aws_db_instance" "postgres" {
  identifier        = "lead-distribution-postgres"
  engine            = "postgres"
  engine_version    = "17.2"        # Latest PostgreSQL 17.2
  instance_class    = "db.t3.micro" # Smallest instance class available
  allocated_storage = 20            # Minimum storage required
  storage_type      = "standard"    # Cheapest storage type

  db_name  = "odoo"
  username = "odoouser"
  password = "odoouser"

  skip_final_snapshot     = true
  publicly_accessible     = false
  backup_retention_period = 0 # Disable automated backups to save costs

  # Free tier settings
  multi_az = false

  # Use cheapest storage and IOPS
  iops = 0

  # Parameter group for PostgreSQL 17
  parameter_group_name = "default.postgres17"

  # Additional cost saving settings
  auto_minor_version_upgrade = false                 # Avoid automatic upgrades
  maintenance_window         = "Mon:03:00-Mon:04:00" # Off-peak maintenance
}

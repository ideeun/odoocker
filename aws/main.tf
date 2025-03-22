resource "aws_s3_bucket" "mybucket" {
  bucket = "lead-distribution-app-bucket"
}
resource "aws_db_instance" "postgres" {
  identifier        = "lead-distribution-postgres"
  engine            = "postgres"
  engine_version    = "15.3"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = "odoo"
  username = "odoo"
  password = "odoo"

  skip_final_snapshot = true
  publicly_accessible = false

  # Free tier settings
  multi_az = false

  # Use cheapest storage and IOPS
  iops = 0

  # Basic parameter group
  parameter_group_name = "default.postgres15"
}

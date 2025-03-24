terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # Change this to your preferred region
}

# Create secret for sensitive data
resource "aws_secretsmanager_secret" "odoocker_secrets" {
  name        = "odoocker-secrets"
  description = "Secrets for Odoocker application"
}

resource "aws_secretsmanager_secret_version" "odoocker_secrets" {
  secret_id = aws_secretsmanager_secret.odoocker_secrets.id
  secret_string = jsonencode({
    db_password           = "odoocker123",
    admin_password        = "odoo",
    aws_access_key_id     = "myaccesskey",
    aws_secret_access_key = "mysecretkey"
  })
}

# IAM role for EC2 to access secrets
resource "aws_iam_role" "odoocker_ec2_role" {
  name = "odoocker-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Policy to allow EC2 to access the secrets
resource "aws_iam_policy" "odoocker_secrets_policy" {
  name        = "odoocker-secrets-policy"
  description = "Policy to allow access to Odoocker secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.odoocker_secrets.arn
      },
      {
        Action = [
          "s3:*"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.odoocker_s3.arn}",
          "${aws_s3_bucket.odoocker_s3.arn}/*"
        ]
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "odoocker_secrets_attachment" {
  role       = aws_iam_role.odoocker_ec2_role.name
  policy_arn = aws_iam_policy.odoocker_secrets_policy.arn
}

# Create an instance profile for the EC2 instance
resource "aws_iam_instance_profile" "odoocker_instance_profile" {
  name = "odoocker-instance-profile"
  role = aws_iam_role.odoocker_ec2_role.name
}

# VPC and Network Configuration
resource "aws_vpc" "odoocker_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "odoocker-vpc"
  }
}

# First subnet in us-east-1a
resource "aws_subnet" "odoocker_subnet_1" {
  vpc_id                  = aws_vpc.odoocker_vpc.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "odoocker-subnet-1"
  }
}

# Second subnet in us-east-1b
resource "aws_subnet" "odoocker_subnet_2" {
  vpc_id                  = aws_vpc.odoocker_vpc.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "odoocker-subnet-2"
  }
}

resource "aws_internet_gateway" "odoocker_igw" {
  vpc_id = aws_vpc.odoocker_vpc.id

  tags = {
    Name = "odoocker-igw"
  }
}

resource "aws_route_table" "odoocker_rt" {
  vpc_id = aws_vpc.odoocker_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.odoocker_igw.id
  }

  tags = {
    Name = "odoocker-rt"
  }
}

resource "aws_route_table_association" "odoocker_rta_1" {
  subnet_id      = aws_subnet.odoocker_subnet_1.id
  route_table_id = aws_route_table.odoocker_rt.id
}

resource "aws_route_table_association" "odoocker_rta_2" {
  subnet_id      = aws_subnet.odoocker_subnet_2.id
  route_table_id = aws_route_table.odoocker_rt.id
}

# Security Groups
resource "aws_security_group" "odoocker_ec2_sg" {
  name        = "odoocker-ec2-sg"
  description = "Security group for Odoocker EC2 instance"
  vpc_id      = aws_vpc.odoocker_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8069
    to_port     = 8069
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8070
    to_port     = 8072
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9001
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
    Name = "odoocker-ec2-sg"
  }
}

resource "aws_security_group" "odoocker_rds_sg" {
  name        = "odoocker-rds-sg"
  description = "Security group for Odoocker RDS instance"
  vpc_id      = aws_vpc.odoocker_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow PostgreSQL access from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "odoocker-rds-sg"
  }
}

# EC2 Instance
resource "aws_instance" "odoocker_ec2" {
  ami                  = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS
  instance_type        = "t2.micro"              # Cheapest instance type
  subnet_id            = aws_subnet.odoocker_subnet_1.id
  iam_instance_profile = aws_iam_instance_profile.odoocker_instance_profile.name

  vpc_security_group_ids = [aws_security_group.odoocker_ec2_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              # Update system and install required packages
              apt-get update
              apt-get install -y docker.io docker-compose git awscli jq

              # Start and enable Docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu

              # Create and setup Odoocker directory
              mkdir -p /opt/odoocker
              cd /opt/odoocker

              # Clone Odoocker repository
              git clone https://github.com/odoocker/odoocker.git .

              # Get the instance's public IP
              PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

              # Get secrets from AWS Secrets Manager
              REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
              SECRETS=$(aws secretsmanager get-secret-value --secret-id odoocker-secrets --region $REGION --query SecretString --output text)
              
              # Extract values from secrets
              DB_PASSWORD=$(echo $SECRETS | jq -r '.db_password')
              ADMIN_PASSWORD=$(echo $SECRETS | jq -r '.admin_password')
              AWS_ACCESS_KEY=$(echo $SECRETS | jq -r '.aws_access_key_id')
              AWS_SECRET_KEY=$(echo $SECRETS | jq -r '.aws_secret_access_key')

              # Create .env file with the correct configuration
              cat > .env << ENV_EOF
              #--------------------------#
              #    Main Configuration    #
              #--------------------------#
              # Odoo
              APP_ENV=production
              INIT=base
              UPDATE=base
              LOAD=base,web
              ROOT_PATH=/usr/lib/python3/dist-packages/odoo
              WORKERS=2
              DOMAIN=$PUBLIC_IP
              ADMIN_PASSWD=$ADMIN_PASSWORD
              DEV_MODE=

              # Services
              PROJECT_NAME=odoocker
              SERVICES=odoo,nginx,proxy

              # Service configuration
              USE_REDIS=false
              USE_S3=true
              USE_SENTRY=false
              USE_PGADMIN=false

              # Database
              DB_HOST=${aws_db_instance.odoocker_rds.endpoint}
              DB_PORT=5432
              DB_NAME=odoocker
              DB_USER=odoo
              DB_PASSWORD=$DB_PASSWORD
              LOAD_LANGUAGE=

              DB_SSLMODE=prefer
              DB_MAXCONN=64
              DB_TEMPLATE=unaccent_template
              UNACCENT=False
              LIST_DB=True
              DBFILTER=.*

              # Logging
              LOG_LEVEL=info
              LOG_HANDLER_LEVEL=INFO

              # S3 Configuration
              AWS_HOST=https://s3.amazonaws.com
              AWS_REGION=$REGION
              AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY
              AWS_SECRET_ACCESS_KEY=$AWS_SECRET_KEY
              AWS_BUCKETNAME=${aws_s3_bucket.odoocker_s3.id}

              # Docker
              COMPOSE_PROJECT_NAME=odoocker
              DOCKER_SOCK=/var/run/docker.sock
              TEMP_DOCKER_SOCK=/tmp/docker.sock

              # Postgres
              POSTGRES_HOST=${aws_db_instance.odoocker_rds.endpoint}
              POSTGRES_PORT=5432
              POSTGRES_DB=odoocker
              POSTGRES_USER=odoo
              POSTGRES_PASSWORD=$DB_PASSWORD
              PGDATA=/var/lib/postgresql/data/odoocker

              # Nginx
              NGINX_CONF=/etc/nginx/nginx.conf
              NGINX_DEFAULT_CONF=/etc/nginx/conf.d/default.conf
              VIRTUAL_HOST=$PUBLIC_IP
              LETSENCRYPT_HOST=$PUBLIC_IP
              LETSENCRYPT_EMAIL=admin@example.com
              CORS_ALLOWED_DOMAIN="'*'"
              ENV_EOF

              # Start Odoocker
              docker-compose up -d
              EOF

  tags = {
    Name = "odoocker-ec2"
  }
}

# EBS volume
resource "aws_ebs_volume" "odoocker_data" {
  availability_zone = aws_subnet.odoocker_subnet_1.availability_zone
  size              = 50
  type              = "gp3"

  tags = {
    Name = "odoocker-data"
  }
}

resource "aws_volume_attachment" "odoocker_data_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.odoocker_data.id
  instance_id = aws_instance.odoocker_ec2.id
}

# RDS Instance (PostgreSQL 16.3)
resource "aws_db_instance" "odoocker_rds" {
  identifier        = "odoocker-db"
  engine            = "postgres"
  engine_version    = "16.3"
  instance_class    = "db.t3.micro" # Cheapest RDS instance type
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "odoocker"
  username = "odoo"
  password = "odoocker123" # Changed from "odoo" to meet AWS password requirements

  vpc_security_group_ids = [aws_security_group.odoocker_rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.odoocker.name

  skip_final_snapshot = true
  publicly_accessible = true # Made RDS publicly accessible

  # Keep existing encryption setting to avoid replacement
  storage_encrypted = false

  # Improved network settings for better connectivity
  backup_retention_period    = 1
  backup_window              = "03:00-04:00"
  maintenance_window         = "sun:04:30-sun:05:30"
  auto_minor_version_upgrade = true

  # Apply parameter group with maximum permissions
  parameter_group_name = aws_db_parameter_group.odoocker_params.name

  tags = {
    Name = "odoocker-rds"
  }
}

# Create a parameter group to set up maximum permissions
resource "aws_db_parameter_group" "odoocker_params" {
  name   = "odoocker-params"
  family = "postgres16"

  description = "Parameters for Odoocker PostgreSQL database"

  # Parameters to maximize privileges while respecting AWS RDS limitations
  parameter {
    name         = "rds.force_ssl"
    value        = "0"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "max_connections"
    value        = "100"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "shared_buffers"
    value        = "{DBInstanceClassMemory/32768}"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "work_mem"
    value        = "16384"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "maintenance_work_mem"
    value        = "65536"
    apply_method = "pending-reboot"
  }
}

# Add RDS instance initialization script to set maximum user privileges and enhance connectivity
resource "null_resource" "setup_db_user_privileges" {
  depends_on = [aws_db_instance.odoocker_rds]

  provisioner "local-exec" {
    command = <<-EOT
      # Wait for RDS to be fully available
      sleep 60
      
      # Use psql to connect and grant maximum allowable privileges
      PGPASSWORD=odoocker123 psql -h ${aws_db_instance.odoocker_rds.address} -p 5432 -U odoo -d odoocker -c "
        -- Grant create database privileges to the odoo user (next best thing to superuser)
        ALTER USER odoo WITH CREATEDB CREATEROLE;
        
        -- Grant all privileges on all tables
        GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO odoo;
        
        -- Grant all privileges on all sequences
        GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO odoo;
        
        -- Grant all privileges on all functions
        GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO odoo;
        
        -- Set default privileges for future objects
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO odoo;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO odoo;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON FUNCTIONS TO odoo;
        
        -- Create extension if allowed
        CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
        CREATE EXTENSION IF NOT EXISTS unaccent;
      "
      
      # Try to create additional extensions in separate commands to avoid errors
      PGPASSWORD=odoocker123 psql -h ${aws_db_instance.odoocker_rds.address} -p 5432 -U odoo -d odoocker -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";" || true
      PGPASSWORD=odoocker123 psql -h ${aws_db_instance.odoocker_rds.address} -p 5432 -U odoo -d odoocker -c "CREATE EXTENSION IF NOT EXISTS postgis;" || true
      
      # Create read-only user and roles in separate commands
      PGPASSWORD=odoocker123 psql -h ${aws_db_instance.odoocker_rds.address} -p 5432 -U odoo -d odoocker -c "
        -- Create an additional read-only user for reporting purposes
        CREATE USER readonly WITH PASSWORD 'readonly123';
        GRANT CONNECT ON DATABASE odoocker TO readonly;
        GRANT USAGE ON SCHEMA public TO readonly;
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly;
      " || true
      
      PGPASSWORD=odoocker123 psql -h ${aws_db_instance.odoocker_rds.address} -p 5432 -U odoo -d odoocker -c "
        -- Create a public role for universal read access
        CREATE ROLE public_access;
        GRANT CONNECT ON DATABASE odoocker TO public_access;
        GRANT USAGE ON SCHEMA public TO public_access;
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO public_access;
      " || true
      
      # Update PostgreSQL performance parameters if possible
      PGPASSWORD=odoocker123 psql -h ${aws_db_instance.odoocker_rds.address} -p 5432 -U odoo -d odoocker -c "
        ALTER SYSTEM SET tcp_keepalives_idle = 60;
        ALTER SYSTEM SET tcp_keepalives_interval = 60;
        ALTER SYSTEM SET tcp_keepalives_count = 10;
      " || true
    EOT
  }
}

# Update DB subnet group to use both subnets
resource "aws_db_subnet_group" "odoocker" {
  name       = "odoocker-db-subnet-group"
  subnet_ids = [aws_subnet.odoocker_subnet_1.id, aws_subnet.odoocker_subnet_2.id]

  tags = {
    Name = "odoocker-db-subnet-group"
  }
}

# S3 Bucket
resource "aws_s3_bucket" "odoocker_s3" {
  bucket = "odoocker-attachments"

  tags = {
    Name = "odoocker-s3"
  }
}

resource "aws_s3_bucket_versioning" "odoocker_s3_versioning" {
  bucket = aws_s3_bucket.odoocker_s3.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Removed public access block to allow public access
resource "aws_s3_bucket_public_access_block" "odoocker_s3_public_access" {
  bucket = aws_s3_bucket.odoocker_s3.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Add bucket policy to allow public access
resource "aws_s3_bucket_policy" "odoocker_s3_policy" {
  bucket = aws_s3_bucket.odoocker_s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.odoocker_s3.arn}/*"
      }
    ]
  })
}

# Outputs
output "ec2_public_ip" {
  value = aws_instance.odoocker_ec2.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.odoocker_rds.endpoint
}

output "s3_bucket_name" {
  value = aws_s3_bucket.odoocker_s3.id
}

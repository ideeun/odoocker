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
  auto_minor_version_upgrade = false # Avoid automatic upgrades
  maintenance_window         = "Mon:03:00-Mon:04:00"
}

# Security group for EC2 instance
resource "aws_security_group" "odoo_sg" {
  name        = "odoo-security-group"
  description = "Allow traffic for Odoo server"

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Consider restricting to your IP for production
  }

  # HTTP access
  ingress {
    from_port   = 8069
    to_port     = 8069
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Longpolling port for Odoo
  ingress {
    from_port   = 8072
    to_port     = 8072
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance for Odoo
resource "aws_instance" "odoo_server" {
  ami                    = "ami-0c7217cdde317cfec" # Amazon Linux 2023 AMI (free tier eligible)
  instance_type          = "t3.micro"              # Free tier eligible, smallest viable for Odoo
  vpc_security_group_ids = [aws_security_group.odoo_sg.id]

  # Root volume - minimal size to keep costs down
  root_block_device {
    volume_size = 8     # Minimum recommended for OS + Odoo
    volume_type = "gp3" # Most cost-effective option with decent performance
  }

  # Spot instance request for maximum cost savings
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = "0.01" # Set a maximum price you're willing to pay
    }
  }

  # User data to install Odoo automatically
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install -y docker
              yum install -y git docker-compose

              # Install Docker
              systemctl enable docker
              systemctl start docker
              
              # Clone your Odoocker repository
              cd /home/ec2-user
              git clone https://github.com/kbKenz/odoocker.git
              cd odoocker
              
              # Configure environment
              cp .env.example .env
              
              # Update database configuration to point to RDS
              sed -i 's/DB_HOST=postgres/DB_HOST=${aws_db_instance.postgres.address}/' .env
              sed -i 's/DB_PORT=5432/DB_PORT=5432/' .env
              sed -i 's/DB_NAME=.*/DB_NAME=odoo/' .env
              sed -i 's/DB_USER=.*/DB_USER=odoouser/' .env
              sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=odoouser/' .env
              
              # Configure S3 storage
              sed -i 's/USE_S3=.*/USE_S3=true/' .env
              sed -i 's/AWS_BUCKETNAME=.*/AWS_BUCKETNAME=lead-distribution-app-bucket/' .env
              sed -i 's/AWS_REGION=.*/AWS_REGION=${aws_s3_bucket.mybucket.region}/' .env
              sed -i 's/AWS_ACCESS_KEY_ID=.*/AWS_ACCESS_KEY_ID=${aws_iam_access_key.odoo_user.id}/' .env
              sed -i 's/AWS_SECRET_ACCESS_KEY=.*/AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.odoo_user.secret}/' .env
              
              # Use the appropriate docker-compose override
              cp docker-compose.override.production.yml docker-compose.override.yml
              
              # Start the services (excluding postgres since we're using RDS)
              sed -i 's/SERVICES=.*/SERVICES=odoo,nginx,proxy/' .env
              
              # Start Odoocker
              docker-compose up -d
              EOF

  tags = {
    Name = "Odoo-Server"
  }
}

# IAM user for S3 access
resource "aws_iam_user" "odoo_user" {
  name = "odoo-s3-user"
}

resource "aws_iam_access_key" "odoo_user" {
  user = aws_iam_user.odoo_user.name
}

resource "aws_iam_user_policy" "odoo_s3_policy" {
  name = "odoo-s3-policy"
  user = aws_iam_user.odoo_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.mybucket.arn}",
          "${aws_s3_bucket.mybucket.arn}/*"
        ]
      }
    ]
  })
}

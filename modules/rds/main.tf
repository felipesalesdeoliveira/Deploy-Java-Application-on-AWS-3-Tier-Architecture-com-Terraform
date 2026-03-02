resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name}-db-subnet-group"
  })
}

resource "aws_security_group" "rds" {
  name        = "${var.name}-rds-sg"
  description = "RDS MySQL access security group"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_cidr_blocks
    content {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "MySQL from allowed CIDR"
    }
  }

  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      from_port       = 3306
      to_port         = 3306
      protocol        = "tcp"
      security_groups = [ingress.value]
      description     = "MySQL from allowed security group"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-rds-sg"
  })
}

resource "aws_db_instance" "primary" {
  identifier                 = "${var.name}-mysql-primary"
  engine                     = "mysql"
  engine_version             = var.engine_version
  instance_class             = var.instance_class
  allocated_storage          = var.allocated_storage
  max_allocated_storage      = var.allocated_storage * 2
  db_name                    = var.db_name
  username                   = var.db_username
  password                   = var.db_password
  db_subnet_group_name       = aws_db_subnet_group.this.name
  vpc_security_group_ids     = [aws_security_group.rds.id]
  storage_encrypted          = true
  multi_az                   = var.multi_az
  backup_retention_period    = var.backup_retention_period
  skip_final_snapshot        = true
  deletion_protection        = var.deletion_protection
  auto_minor_version_upgrade = true
  publicly_accessible        = false
  apply_immediately          = true

  tags = merge(var.tags, {
    Name = "${var.name}-mysql-primary"
  })
}

resource "aws_db_instance" "replicas" {
  count = var.replica_count

  identifier                 = "${var.name}-mysql-replica-${count.index + 1}"
  replicate_source_db        = aws_db_instance.primary.identifier
  instance_class             = var.instance_class
  auto_minor_version_upgrade = true
  publicly_accessible        = false
  apply_immediately          = true

  tags = merge(var.tags, {
    Name = "${var.name}-mysql-replica-${count.index + 1}"
  })
}

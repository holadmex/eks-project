# # Database Subnet Group using existing private subnets
# resource "aws_db_subnet_group" "main" {
#   name       = "${var.cluster_name}-db-subnet-group"
#   subnet_ids = aws_subnet.private[*].id

#   tags = {
#     Name = "${var.cluster_name}-db-subnet-group"
#   }
# }

# # Database Security Group
# resource "aws_security_group" "rds" {
#   name_prefix = "${var.cluster_name}-rds-"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     from_port       = 5432
#     to_port         = 5432
#     protocol        = "tcp"
#     security_groups = [aws_security_group.eks_nodes.id]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "${var.cluster_name}-rds-sg"
#   }
# }

# # RDS PostgreSQL Instance
# resource "aws_db_instance" "postgres" {
#   identifier = "${var.cluster_name}-postgres"

#   engine         = "postgres"
#   engine_version = "17.4"
#   instance_class = var.db_instance_class

#   allocated_storage     = 20
#   max_allocated_storage = 100
#   storage_type          = "gp2"
#   storage_encrypted     = true
#   kms_key_id            = aws_kms_key.eks.arn

#   db_name  = var.db_name
#   username = var.db_username
#   password = random_password.db_password.result

#   vpc_security_group_ids = [aws_security_group.rds.id]
#   db_subnet_group_name   = aws_db_subnet_group.main.name

#   backup_retention_period = 7
#   backup_window           = "03:00-04:00"
#   maintenance_window      = "sun:04:00-sun:05:00"

#   skip_final_snapshot = true
#   deletion_protection = false

#   performance_insights_enabled = true
#   monitoring_interval          = 60
#   monitoring_role_arn          = aws_iam_role.rds_monitoring.arn

#   enabled_cloudwatch_logs_exports = ["postgresql"]

#   tags = {
#     Name = "${var.cluster_name}-postgres"
#   }
# }

# # RDS Monitoring Role
# resource "aws_iam_role" "rds_monitoring" {
#   name = "${var.cluster_name}-rds-monitoring-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "monitoring.rds.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "rds_monitoring" {
#   role       = aws_iam_role.rds_monitoring.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
# }
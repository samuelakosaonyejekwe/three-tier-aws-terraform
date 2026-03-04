resource "aws_db_subnet_group" "aurora" {
  name       = "${local.name}-aurora-subnets"
  subnet_ids = [aws_subnet.db_private[0].id, aws_subnet.db_private[1].id]

  tags = merge(local.common_tags, { Name = "${local.name}-aurora-subnets" })
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier     = "${local.name}-aurora"
  engine                 = "aurora-mysql"
  engine_version         = var.aurora_engine_version
  database_name          = var.db_name
  master_username        = var.db_master_username
  master_password        = var.db_master_password
  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  skip_final_snapshot = true

  tags = merge(local.common_tags, { Name = "${local.name}-aurora" })
}

resource "aws_rds_cluster_instance" "writer" {
  identifier         = "${local.name}-aurora-writer"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = var.aurora_instance_class
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version

  tags = merge(local.common_tags, { Name = "${local.name}-aurora-writer" })
}

resource "aws_rds_cluster_instance" "reader" {
  identifier         = "${local.name}-aurora-reader"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = var.aurora_instance_class
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version

  tags = merge(local.common_tags, { Name = "${local.name}-aurora-reader" })
}

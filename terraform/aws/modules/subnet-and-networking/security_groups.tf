resource "aws_security_group" "master_sg" {
  for_each = toset(var.vpc_cidrs)

  name        = format("%s-%s-master-sg", var.name, join("", split(".", split("/", each.value)[0])))
  description = "Master Nodes Security Group"
  vpc_id = data.aws_vpc.vpc_ids[each.value]["id"]
  tags = merge(
    {
     "Name" = format("%s-%s-master-sg", var.name, join("", split(".", split("/", each.value)[0]))),
     "NodeType" = "master"
    },
    var.tags
  )
}

resource "aws_security_group" "worker_sg" {
  for_each = toset(var.vpc_cidrs)

  name        = format("%s-%s-worker-sg", var.name, join("", split(".", split("/", each.value)[0])))
  description = "Worker Nodes Security Group"
  vpc_id = data.aws_vpc.vpc_ids[each.value]["id"]
  tags = merge(
    {
     "Name" = format("%s-%s-worker-sg", var.name, join("", split(".", split("/", each.value)[0]))),
     "NodeType" = "worker"
    },
    var.tags
  )
}

resource "aws_security_group" "db_sg" {
  for_each = toset(var.vpc_cidrs)

  name        = format("%s-%s-db-sg", var.name, join("", split(".", split("/", each.value)[0])))
  description = "RDS Database Security Group"
  vpc_id = data.aws_vpc.vpc_ids[each.value]["id"]
  tags = merge(
    {
     "Name" = format("%s-%s-db-sg", var.name, join("", split(".", split("/", each.value)[0]))),
     "MattermostCloudInstallationDatabase" = "MYSQL/Aurora"
    },
    var.tags
  )
}

# Master Rules
resource "aws_security_group_rule" "master_egress" {
  for_each = toset(var.vpc_cidrs)

  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Outbound Traffic"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.master_sg[each.value]["id"]
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "master_ingress_worker" {
  for_each = toset(var.vpc_cidrs)

  source_security_group_id = aws_security_group.worker_sg[each.value]["id"]
  description       = "Ingress Traffic from Worker Nodes"
  from_port         = 443
  protocol          = "TCP"
  security_group_id = aws_security_group.master_sg[each.value]["id"]
  to_port           = 443
  type              = "ingress"
}

# Worker Rules
resource "aws_security_group_rule" "worker_egress" {
  for_each = toset(var.vpc_cidrs)

  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Outbound Traffic"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.worker_sg[each.value]["id"]
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "worker_ingress_worker" {
  for_each = toset(var.vpc_cidrs)

  self = true
  description       = "Ingress Traffic from Worker Nodes"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.worker_sg[each.value]["id"]
  to_port           = 0
  type              = "ingress"
}

resource "aws_security_group_rule" "worker_ingress_master" {
  for_each = toset(var.vpc_cidrs)

  source_security_group_id = aws_security_group.master_sg[each.value]["id"]
  description       = "Ingress Traffic from Master Nodes"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.worker_sg[each.value]["id"]
  to_port           = 0
  type              = "ingress"
}

# DB Rules
resource "aws_security_group_rule" "db_ingress_worker" {
  for_each = toset(var.vpc_cidrs)

  source_security_group_id = aws_security_group.worker_sg[each.value]["id"]
  description       = "Ingress Traffic from Worker Nodes"
  from_port         = 3306
  protocol          = "TCP"
  security_group_id = aws_security_group.db_sg[each.value]["id"]
  to_port           = 3306
  type              = "ingress"
}

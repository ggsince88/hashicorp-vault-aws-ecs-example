
resource "aws_security_group" "ecs_security_group" {
    name = "ecs-${var.environment}-utility-01-sg"
    description = "Main security group for utility ECS Utility Cluster"
    vpc_id = var.vpc_id

    tags = {
        Name = "sg-ecs-${var.environment}-utility-01"
        terraform = "true"
        environment = var.environment
        vault-example = "true"
    }
}

resource "aws_security_group_rule" "allow_ssh_local" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    security_group_id = aws_security_group.ecs_security_group.id
}

resource "aws_security_group_rule" "allow_vault_cluster_comm" {
    type = "ingress"
    from_port = 8200
    to_port = 8201
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    security_group_id = aws_security_group.ecs_security_group.id
}

resource "aws_security_group_rule" "allow_egress" {
    type = "egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.ecs_security_group.id
}

resource "aws_security_group" "lb_security_group" {
    name = "elb-${var.environment}-utility-01-sg"
    description = "Main security group for vault ELB"
    vpc_id = var.vpc_id

    tags = {
        Name = "sg-elb-${var.environment}-utility-01"
        terraform = "true"
        environment = var.environment
    }
}

resource "aws_security_group_rule" "allow_http" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.lb_security_group.id
}

resource "aws_security_group_rule" "allow_https" {
    type = "ingress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.lb_security_group.id
}

resource "aws_security_group_rule" "allow_vault_http" {
    type = "ingress"
    from_port = 8200
    to_port = 8200
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.lb_security_group.id
}

resource "aws_security_group_rule" "allow_vault_https" {
    type = "ingress"
    from_port = 8201
    to_port = 8201
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    security_group_id = aws_security_group.lb_security_group.id
}

resource "aws_security_group_rule" "allow_lb_egress" {
    type = "egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.lb_security_group.id
}

resource "aws_lb" "this_lb" {
    name = "elb-${var.environment}-utility-01"
    internal = var.internal_elb
    load_balancer_type = "application"
    security_groups = ["${aws_security_group.lb_security_group.id}"]
    subnets = var.elb_subnets

    tags = {
        environment = var.environment
        terraform = "true"
    }

}

resource "aws_lb_listener" "this_lb_listener_http" {
    load_balancer_arn = aws_lb.this_lb.arn
    port = "80"
    protocol = "HTTP"

    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "No route found"
            status_code = "200"
        }
    }

}

resource "aws_route53_record" "vault_subdomain" {
    count = var.route53_zone_id != "" ? 1 : 0
    zone_id = var.route53_zone_id
    name    = var.vault_subdomain
    type    = "CNAME"
    ttl     = "300"
    records = ["${aws_lb.this_lb.dns_name}"]
}
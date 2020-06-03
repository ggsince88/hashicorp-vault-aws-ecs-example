
resource "aws_iam_service_linked_role" "ecs_service_linked_role" {
    aws_service_name = "ecs.amazonaws.com"
}

resource "aws_iam_role_policy_attachment" "default_ecs_attachment" {
    role = aws_iam_role.role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role" "role" {
    name = "ecs-utility-role"
    path = "/"
    # ECS Service Linked role MUST be created before role is created
    depends_on = [ aws_iam_service_linked_role.ecs_service_linked_role ]
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": ["ec2.amazonaws.com", "ecs.amazonaws.com"]
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
    EOF
}

resource "aws_iam_instance_profile" "utility" {
    name = "ecs-utility-role"
    role = aws_iam_role.role.name
}

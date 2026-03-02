resource "aws_iam_role" "ec2" {
  name = "${var.name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy" "ec2_describe_elb" {
  name = "${var.name}-ec2-describe-elb"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "elasticloadbalancing:DescribeLoadBalancers"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_security_group" "frontend" {
  name        = "${var.name}-frontend-sg"
  description = "Frontend Nginx security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.ingress_http_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-frontend-sg"
  })
}

resource "aws_security_group" "backend" {
  name        = "${var.name}-backend-sg"
  description = "Backend Tomcat security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
    description     = "Allow frontend tier to reach backend tier"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-backend-sg"
  })
}

resource "aws_lb" "frontend" {
  name               = "${var.name}-front-nlb"
  load_balancer_type = "network"
  internal           = false
  subnets            = var.public_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name}-front-nlb"
  })
}

resource "aws_lb" "backend" {
  name               = "${var.name}-back-nlb"
  load_balancer_type = "network"
  internal           = true
  subnets            = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name}-back-nlb"
  })
}

resource "aws_lb_target_group" "frontend" {
  name        = "${var.name}-front-tg"
  port        = 80
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    protocol = "TCP"
    port     = "80"
  }

  tags = var.tags
}

resource "aws_lb_target_group" "backend" {
  name        = "${var.name}-back-tg"
  port        = 8080
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    protocol = "TCP"
    port     = "8080"
  }

  tags = var.tags
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.backend.arn
  port              = 8080
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

resource "aws_launch_template" "frontend" {
  name_prefix   = "${var.name}-front-"
  image_id      = var.ami_id
  instance_type = var.instance_type_frontend
  user_data     = base64encode(var.frontend_user_data)

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  network_interfaces {
    security_groups             = [aws_security_group.frontend.id]
    associate_public_ip_address = false
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(var.tags, {
      Name = "${var.name}-frontend"
      Tier = "frontend"
    })
  }
}

resource "aws_launch_template" "backend" {
  name_prefix   = "${var.name}-back-"
  image_id      = var.ami_id
  instance_type = var.instance_type_backend
  user_data     = base64encode(var.backend_user_data)

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  network_interfaces {
    security_groups             = [aws_security_group.backend.id]
    associate_public_ip_address = false
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(var.tags, {
      Name = "${var.name}-backend"
      Tier = "backend"
    })
  }
}

resource "aws_autoscaling_group" "frontend" {
  name                = "${var.name}-front-asg"
  desired_capacity    = var.frontend_desired
  max_size            = var.frontend_max
  min_size            = var.frontend_min
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.frontend.arn]
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.frontend.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-frontend"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "backend" {
  name                = "${var.name}-back-asg"
  desired_capacity    = var.backend_desired
  max_size            = var.backend_max
  min_size            = var.backend_min
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.backend.arn]
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-backend"
    propagate_at_launch = true
  }
}

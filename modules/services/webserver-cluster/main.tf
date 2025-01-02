/*resource "aws_launch_configuration" "example" {
  image_id        = "ami-042e76978adeb8c48"
  instance_type   = "t3.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html 
                nohup busybox httpd -f -p ${var.server_port} &
                EOF
  lifecycle {
    create_before_destroy = true
  }
}*/

resource "aws_launch_template" "example" {
  image_id               = "ami-0b40dea19b4538863"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
  server_port = var.server_port
  db_address = data.terraform_remote_state.db.outputs.address
  db_port = data.terraform_remote_state.db.outputs.port
}))
}


resource "aws_autoscaling_group" "example" {
  # launch_configuration = aws_launch_configuration.example.name
  launch_template {
    id = aws_launch_template.example.id
  }
  target_group_arns = [aws_lb_target_group.asg.arn]
  vpc_zone_identifier = data.aws_subnets.default.ids
  min_size            = 2
  max_size            = 10
  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-asg"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-instance-sg"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "example" {
  name               = "${var.cluster_name}-lb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = local.http_port
  protocol          = "HTTP"
  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener_rule" "asg" {
 listener_arn = aws_lb_listener.http.arn
 priority = 100
 condition {
  path_pattern {
   values = ["*"]
  }
 }
 action {
  type = "forward"
  target_group_arn = aws_lb_target_group.asg.arn
 }
}

resource "aws_security_group" "alb" {
  name = "{var.cluster_name}-alb-sg"
  # Allow inbound HTTP requests
  ingress {
    from_port   = local.http_port
    to_port     = local.http_port
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }
  # Allow all outbound requests
  egress {
    from_port   = local.any_port
    to_port     = local.any_port
    protocol    = local.any_protocol
    cidr_blocks = local.all_ips
  }
}

resource "aws_lb_target_group" "asg" {
 name = "${var.cluster_name}-asg"
 port = var.server_port
 protocol = "HTTP"
 vpc_id = data.aws_vpc.default.id
 health_check {
 path = "/"
 protocol = "HTTP"
 matcher = "200"
 interval = 15
 timeout = 3
 healthy_threshold = 2
 unhealthy_threshold = 2
 }
}

data "aws_vpc" "default" {
  default = true
}
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "terraform_remote_state" "db" {
 backend = "s3"
 config = {
 bucket = "terraform-state-tnghks"
 key = "stage/data-stores/mysql/terraform.tfstate"
 region = "ap-northeast-3"
 }
}
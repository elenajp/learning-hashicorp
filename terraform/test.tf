data "aws_ami" "elena" {

  owners      = ["self"]
  most_recent = true

  filter {
    name   = "name"
    values = ["learn-packer-elena-*"]
  }
}

resource "aws_key_pair" "elena" {
  key_name   = "elena-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

output "instance_id" {
  value = aws_instance.bastion.id
}

output "instance_ip" {
  value = "ssh admin@${aws_instance.bastion.public_ip}"
}

output "vpc" {
  value = module.vpc
}

output "lb_http_url" {
  value = "http://${aws_lb.elena-lb.dns_name}"
}

locals {
  subnet_ids = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
}

resource "aws_security_group" "allow_nomad" {
  name   = "allow_nomad"
  vpc_id = module.vpc.id

  ingress {
    from_port   = 4646
    to_port     = 4646
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elena-LB-SG" {
  name   = "elena-LB-SG"
  vpc_id = module.vpc.id 

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "elena-lb" {
  name            = "test-elena-lb"
  internal        = false
  security_groups = [aws_security_group.elena-LB-SG.id]
  subnets         = local.subnet_ids

  enable_deletion_protection = false

  tags = {
    Environment = "test"
  }
}

// resource "aws_lb_target_group_attachment" "elena-test" {
//   target_group_arn = aws_lb_target_group.elena-TG.arn
//   target_id        = aws_instance.ec2_test.id
//   port             = 8081
// }

resource "aws_lb_target_group" "elena-TG" {
  name     = "elena-TG"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = module.vpc.id

  health_check {
    path                = "/"
    port                = 8081
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 5
    matcher             = 200
  }
}

resource "aws_lb_listener" "elena-listener" {
  load_balancer_arn = aws_lb.elena-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.elena-TG.arn
  }
}

resource "aws_launch_template" "elena-template" {
  name                    = "elena-template"
  image_id                = data.aws_ami.elena.id
  disable_api_termination = true
  instance_type           = "t3.micro"
  key_name                = "elena-key"
}

resource "aws_autoscaling_group" "elena-ASG" {
  name                      = "elena-ASG-nomad"
  max_size                  = 5
  min_size                  = 2
  desired_capacity          = 3
  health_check_grace_period = 200
  health_check_type         = "EC2"

  launch_template {
    id      = aws_launch_template.elena-template.id
    version = "$Latest"
  }

  vpc_zone_identifier  = local.private_subnet_ids
}
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

output "vpc" {
  value = module.vpc
}

output "lb_http_url" {
  value = "http://${aws_lb.elena-lb.dns_name}"
}

locals {
  subnet_ids         = module.vpc.public_subnet_ids
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

  ingress {
    from_port   = 8080
    to_port     = 8080
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

resource "aws_lb_target_group_attachment" "elena-test" {
  target_group_arn = aws_lb_target_group.elena-TG.arn
  target_id        = aws_instance.docker_host.id
  port             = 8080
}


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

resource "aws_autoscaling_group" "elena-ASG" {
  name                      = "elena-ASG-nomad"
  max_size                  = 5
  min_size                  = 2
  desired_capacity          = 3
  health_check_grace_period = 200
  health_check_type         = "EC2"

  tag {
    key                 = "Name"
    value               = "Test-ASG"
    propagate_at_launch = true
  }

  launch_template {
    id      = aws_launch_template.elena-template.id
    version = "$Latest"
  }

  vpc_zone_identifier  = local.private_subnet_ids

}

## Cloud init allows you to pass a shell script to your instance that installs or configures the machine to your specifications.

# First we can define a cloud-init configuration in `cloud-init.tpl` 

##cloud-config
#
# runcmd:
#   - echo "plop"
#   - touch /tmp/pouet
#
# write_files:
# - path: /tmp/toto.txt
#   content: |
#     random content
#
# - path: /tmp/another_file
#   content: plop
#
#
# Then in terraform code we use the cloudinit_config data source: https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/cloudinit_config
# to transform the configuration in the right format for AWS user data.
# 
data "cloudinit_config" "user_data" {
  gzip          = false
  base64_encode = true

  part {
    filename     = "cloud/init.yml.tpl"
    content_type = "text/cloud-config"
    content = file("${path.module}/cloud-init.yml.tpl")
  }
}

//
// Then in the aws_launch_template: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template#user_data
// we fill the user_data (that all instances of the ASG will have) with this cloud_config rendered.
//
//  resource "aws_launch_template" "XXX" {
//     [...]
//     user_data = data.cloudinit_config.user_data.rendered
//  }


// Use an instance profile to pass an IAM role to an EC2 instance (remember to pass it to the aws_instance below)
resource "aws_iam_instance_profile" "docker_host" {
  name = "docker_host"
  role = aws_iam_role.docker_host.name
}

resource "aws_iam_role" "docker_host" {
  name = "docker_host"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
        {
            Action = "sts:AssumeRole"
            Principal = {
              Service = "ec2.amazonaws.com"
            }
            Effect = "Allow"
            Sid = ""
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "docker_host_describe" {
  role       = aws_iam_role.docker_host.name
  policy_arn = aws_iam_policy.describe_ec2.arn
}

resource "aws_launch_template" "elena-template" {
  name                    = "elena-template"
  image_id                = data.aws_ami.elena.id
  instance_type           = "t3.micro"
  key_name                = "elena-key"
  user_data               = data.cloudinit_config.user_data.rendered
}

resource "aws_instance" "docker_host" {
  ami                    = data.aws_ami.elena.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnet_ids[0]
  key_name               = aws_key_pair.elena.key_name
  vpc_security_group_ids = [aws_security_group.allow_nomad.id]
  iam_instance_profile   = aws_iam_instance_profile.docker_host.name

  user_data              = templatefile("${path.module}/cloud-init.yml.tpl", {
    encryption_key   = local.consul_encryption_key
    datacenter       = local.consul_datacenter
    consul_cluster   = local.stack_id
    nomad_datacenter = local.nomad_datacenter
    nomad_region     = local.nomad_region
    consul_token     = local.consul_master_token
  })

  tags = {
    Name = "Docker host"
  }

  connection {
    type = "ssh"
    user = "admin"
    host = self.public_ip
  }
}


  // provisioner "file" {
  //   destination = "/tmp/consul.json"
  //   content = templatefile("${path.module}/consul.json", {
  //     encryption_key = local.consul_encryption_key
  //     datacenter     = local.consul_datacenter
  //     consul_cluster = local.stack_id
  //   })
  // }

// provisioner "file" {
//   destination = "/tmp/nomad.json"
//   content = templatefile("${path.module}/nomad.json", {
//     nomad_datacenter = local.nomad_datacenter
//     nomad_region     = local.nomad_region
//     consul_token     = local.consul_master_token
//   })
// }

// provisioner "remote-exec" {
//   inline = [
//     "sudo mkdir /etc/consul",
//     "sudo mv /tmp/consul.json /etc/consul/config.json",
//     "sudo systemctl start consul",
//   ]
// }

// provisioner "remote-exec" {
//   inline = [
//     "sudo mkdir /etc/nomad",
//     "sudo mv /tmp/nomad.json /etc/nomad/config.json",
//     "sudo systemctl start nomad",
//   ]
// }

output "docker_host_id" {
  value = aws_instance.bastion.id
}

output "docker_host_ip" {
  value = "ssh admin@${aws_instance.docker_host.public_ip}"
}
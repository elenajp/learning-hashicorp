resource "random_string" "nomad_encryption_key" {
  length = 32
}


module "nomad_server" {
  source = "git@github.com:edgelaboratories/dawn-nomad-server.git//terraform/aws?ref=v21"

  ami_filters = local.ami_filters

  desired_capacity = 3
  instance_type    = "t3.medium"

  nomad_region         = local.nomad_region
  nomad_datacenter     = local.nomad_datacenter
  nomad_encryption_key = local.nomad_encryption_key

  consul_token   = local.consul_master_token
  consul_encryption_key = local.consul_encryption_key

  security_group_ids = [aws_security_group.allow_nomad.id]

  stack_id       = local.stack_id
  vpc_id         = module.vpc.id
  vpc_cidr_block = module.vpc.cidr_block
  subnet_ids     = local.private_subnet_ids

  instance_role_policies_arn = [
    resource.aws_iam_policy.describe_ec2.arn,
  ]
}

resource "aws_lb" "nomad-lb" {
  name            = "test-nomad-lb"
  internal        = false
  security_groups = [aws_security_group.elena-LB-SG.id]
  subnets         = local.subnet_ids

  enable_deletion_protection = false

  tags = {
    Environment = "test"
  }
}

resource "aws_lb_listener" "nomad-listener" {
  load_balancer_arn = aws_lb.nomad-lb.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = module.nomad_server.target_group_arn[0]
  }
}
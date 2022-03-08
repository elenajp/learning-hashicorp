resource "random_string" "consul_encryption_key" {
  length = 32
}


# This module creates the Consul cluster
# (3 servers with an autoscaling group)
module "consul_server" {
  source = "git@github.com:enter_github_org_here/dawn-consul-server.git//terraform/aws?ref=v23"

  stack_id       = local.stack_id
  vpc_id         = module.vpc.id
  vpc_cidr_block = module.vpc.cidr_block
  subnet_ids     = local.private_subnet_ids

  instance_role_policies_arn = [
    resource.aws_iam_policy.describe_ec2.arn,
  ]

  security_group_ids = [aws_security_group.allow_nomad.id]

  ami_filters   = local.ami_filters
  instance_type = "t3.medium"

  consul_datacenter     = local.consul_datacenter
  consul_encryption_key = local.consul_encryption_key

  consul_master_token = local.consul_master_token
  bootstrap_expect    = 2

  desired_capacity = 3
}

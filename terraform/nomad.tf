resource "random_string" "nomad_encryption_key" {
  length = 32
}


module "nomad_server" {
  source      = "git@github.com:edgelaboratories/dawn-nomad-server.git//terraform/aws?ref=v21"

  ami_filters = local.ami_filters

  desired_capacity      = 3
  instance_type         = "t3.medium"
  
  nomad_region         = "test"
  nomad_datacenter     = "test"
  nomad_encryption_key = base64encode(random_string.nomad_encryption_key.result)

  consul_token          = local.consul_master_token
  consul_encryption_key = base64encode(random_string.consul_encryption_key.result)

  security_group_ids = [aws_security_group.allow_nomad.id]

  stack_id       = local.stack_id
  vpc_id         = module.vpc.id
  vpc_cidr_block = module.vpc.cidr_block
  subnet_ids     = local.private_subnet_ids

  instance_role_policies_arn = [
    resource.aws_iam_policy.describe_ec2.arn,
  ]
}

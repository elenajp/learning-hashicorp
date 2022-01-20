data "aws_iam_policy_document" "describe_ec2" {
  // Required by Consul (Cloud auto-join)
  statement {
    actions   = ["ec2:Describe*"]
    resources = ["*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "describe_ec2" {
  name   = "${local.stack_id}_describe_ec2"
  policy = data.aws_iam_policy_document.describe_ec2.json
}

resource "random_string" "consul_encryption_key" {
  length = 32
}

resource "aws_instance" "bastion" {
  ami                    = "ami-04c25a51fac276374"
  instance_type          = var.instance_type
  subnet_id              = module.vpc.public_subnet_ids[0]
  key_name               = aws_key_pair.elena.key_name
  vpc_security_group_ids = [aws_security_group.allow_nomad.id]
  tags = {
    Name = var.instance_name
  }
}

module "consul_server" {
  source = "git@github.com:edgelaboratories/dawn-consul-server.git//terraform/aws?ref=v23"

  stack_id       = local.stack_id
  vpc_id         = module.vpc.id
  vpc_cidr_block = module.vpc.cidr_block
  subnet_ids     = local.private_subnet_ids

  instance_role_policies_arn = [
    resource.aws_iam_policy.describe_ec2.arn,
  ]

  security_group_ids = [aws_security_group.allow_nomad.id]

  ami_filters = local.ami_filters
  instance_type = "t3.medium"

  consul_datacenter     = "test"
  consul_encryption_key = base64encode(random_string.consul_encryption_key.result)
  
  consul_master_token   = local.consul_master_token
  bootstrap_expect      = 2

  desired_capacity = 3
}

module "vpc" {
  source       = "git@github.com:edgelaboratories/dawn-aws-vpc.git//terraform/aws/vpc?ref=v7"
  name         = "VPC: Elena"
  cidr_block   = "192.168.22.0/24"
  subnets_size = 3
  stack_id     = "eperez"
}
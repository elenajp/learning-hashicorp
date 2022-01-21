locals {
  stack_id = "elena"
  ami_filters = {
    "tag:ReleaseTag" = ["release"]
    "tag:Version"    = ["v47"]
  }

  consul_master_token   = "test"
  consul_datacenter     = "test"
  consul_encryption_key = base64encode(random_string.consul_encryption_key.result)

  nomad_region         = "test"
  nomad_datacenter     = "test"
  nomad_encryption_key = base64encode(random_string.consul_encryption_key.result)
}

variable "instance_name" {
  type    = string
  default = "test_instance"
}

variable "ami_name" {
  type    = string
  default = "learn-packer-elena"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
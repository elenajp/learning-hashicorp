locals {
   stack_id = "elena"
   ami_filters = {
    "tag:ReleaseTag" = ["release"]
    "tag:Version"    = ["v47"]
  }

  consul_master_token = "test"
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
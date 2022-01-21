resource "aws_instance" "bastion" {
  ami                    = "ami-04c25a51fac276374"
  instance_type          = var.instance_type
  subnet_id              = module.vpc.public_subnet_ids[0]
  key_name               = aws_key_pair.elena.key_name
  vpc_security_group_ids = [aws_security_group.allow_nomad.id]
  tags = {
    Name = "SSH bastion"
  }
}

output "ssh_bastion_id" {
  value = aws_instance.bastion.id
}

output "ssh_bastion_ip" {
  value = "ssh admin@${aws_instance.bastion.public_ip}"
}
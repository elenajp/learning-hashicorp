packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.6"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "debian" {
  ami_name      = "learn-packer-elena-${formatdate("YYYY-MM-DD_hhmmssZ", timestamp())}"
  instance_type = "t3.micro"
  # https://wiki.debian.org/Cloud/AmazonEC2Image/Bullseye
  source_ami = "ami-0faddff36e930fbd2"
  region = "eu-central-1"

  ssh_username = "admin"

  vpc_filter {
      filters = {
          "tag:Name": "VPC: Elena",
      }
  }

#  subnet_filter {
#    filters = {}
#    random = true  
#  }
  subnet_filter {
    filters = { 
      mapPublicIpOnLaunch = "true"
    }   
    most_free = true
  }

  tags = {
      Name = "learn-packer-elena"
  }
}

build {
  name = "learn_packer"
  sources = [
    "source.amazon-ebs.debian"
  ]

  provisioner "file" {
    source = "nomad.service"
    destination = "/tmp/nomad.service"
  }

  provisioner "shell" {
    script = "./install.sh"
  }
}


    # IN PACKER:
    # Install Docker: https://docs.docker.com/engine/install/debian/
    # Bullseye Debian 11

    # Install Nomad: https://releases.hashicorp.com/nomad/1.2.1/nomad_1.2.1_linux_amd64.zip
    # Download, with curl in the script, unzip (contains a binary called `nomad`) and put in /usr/local/bin

    # packer build .
    



    # IN TERRAFORM
    # Then in the terraform directory, terraform apply will use the new AMI
    # Connect into it with ssh admin@X.X.X.X, and
    # $ sudo nomad agent -dev
    # And you should find the following line on the startup logs:
    # client.driver_mgr: initial driver fingerprint: driver=docker health=healthy description=Healthy
// }




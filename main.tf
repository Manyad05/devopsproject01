
provider "aws" {
  region     = "ap-south-1"
  access_key = "aws_access_key"
  secret_key = "aws_secret_key"
}

# ---- Generate a Key Pair ----
resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-key-pair-${random_id.unique.id}" # Unique name with a random suffix
  public_key = tls_private_key.my_key.public_key_openssh

  depends_on = [tls_private_key.my_key]
}

resource "random_id" "unique" {
  byte_length = 4
}

# ---- Save Private Key Locally ----
resource "local_file" "private_key" {
  content         = tls_private_key.my_key.private_key_pem
  filename        = "/home/manish_007/.ssh/my-key-pair.pem" # Adjust path as needed
  file_permission = "0400" # Read-only for the owner
  depends_on      = [aws_key_pair.my_key_pair]
}

# ---- Create EC2 Instance ----
resource "aws_instance" "my_ec2" {
  ami           = "ami-0c2af51e265bd5e0e" # Ubuntu 22.04 in ap-south-1
  instance_type = "t2.micro"
  key_name      = aws_key_pair.my_key_pair.key_name # Associate the generated key pair

  tags = {
    Name = "Terraform-Ansible-EC2"
  }
monitoring = true
  # Save the public IP for Ansible
  provisioner "local-exec" {
    command = "echo ${self.public_ip} > ../ansible/inventory.ini"
  }
}

# ---- Output the public IP ----
output "instance_ip" {
  value = aws_instance.my_ec2.public_ip
}
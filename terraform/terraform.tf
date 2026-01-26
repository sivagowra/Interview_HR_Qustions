provider "aws" {
  region = "ap-south-1"
}

resource "aws_security_group" "terraform_sg" {
  name = "terraform-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2" {
  ami                    = "ami-0ff5003538b60d5ec" # Amazon Linux 2 (ap-south-1)
  instance_type          = "t2.micro"
  key_name               = "mi_pem"
  availability_zone      = "ap-south-1a"
  vpc_security_group_ids = [aws_security_group.terraform_sg.id]

  user_data = <<-EOF
#!/bin/bash
yum update -y
yum install -y python3

mkdir -p /var/www/html
echo "Hello World from Terraform EC2" > /var/www/html/index.html

cd /var/www/html
nohup python3 -m http.server 8080 &
EOF

  tags = {
    Name = "Terraform-EC2"
  }
}

#vpc
resource "aws_vpc" "node-vpc" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "node-vpc"
  }
}

# internet gateway
resource "aws_internet_gateway" "node-gw" {
  vpc_id = aws_vpc.node-vpc.id

  tags = {
    Name = "node-gw"
  }
}

# public and private subnets
resource "aws_subnet" "public-subnet" {
  count = 2
  vpc_id     = aws_vpc.node-vpc.id
  cidr_block = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private-subnet" {
  count = 2
  vpc_id     = aws_vpc.node-vpc.id
  cidr_block = "10.0.${count.index + 10}.0/24"
  map_public_ip_on_launch = true
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "private-subnet-${count.index}"
  }
}

# eip
resource "aws_eip" "node-eip" {
  count = 1
  domain   = "vpc"
}

# nat gateway
resource "aws_nat_gateway" "node-nat" {
  allocation_id = aws_eip.node-eip[0].id
  subnet_id     = aws_subnet.public-subnet[0].id

  tags = {
    Name = "node-nat"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.node-gw]
}

# public and private route tables
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.node-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.node-gw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.node-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.node-nat.id
  }

  tags = {
    Name = "private-rt"
  }
}

# route table associations
resource "aws_route_table_association" "public-rta" {
  count = length(aws_subnet.public-subnet)
  subnet_id      = aws_subnet.public-subnet[count.index].id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "private-rta" {
  count = length(aws_subnet.private-subnet)
  subnet_id      = aws_subnet.private-subnet[count.index].id
  route_table_id = aws_route_table.private-rt.id
}

# create ecr repository

resource "aws_ecr_repository" "app" {
  name                 = "node-repo"

  image_scanning_configuration {
    scan_on_push = true
  }
  force_delete = true
}
# security groups 
resource "aws_security_group" "tech365-sg" {
    name= "olawale-jenkins-sg"
    description = "Allow SSH and Jenkins web access"

    ingress {
        description = "SSH access from your IP"
        from_port = 22
        to_port = 22
        protocol= "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

     ingress {
        description = "http"
        from_port = 80
        to_port = 80
        protocol= "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "nodejs"
        from_port = 3000
        to_port = 3000
        protocol= "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Jenkins access from your IP"
        from_port = 8080
        to_port = 8080
        protocol= "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol= "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

        tags = {
            Name = "olawale-security-group"
        }
    }

# create an instance 
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "jenkins-server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = var.key_name
   vpc_security_group_ids = [aws_security_group.tech365-sg.id]

    root_block_device {
        volume_size = 30
        volume_type = "gp3"
    }
  user_data = file("./script.sh")

  tags = {
    Name = "jenkins"
  }
}
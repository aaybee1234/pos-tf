# Configure AWS provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "pos-vpc"
  }
}

# Create public subnets in AZ 1a and 1b
resource "aws_subnet" "public_subnet_1a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "public-subnet-1a"
  }
}

resource "aws_subnet" "public_subnet_1b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "public-subnet-1b"
  }
}

# Create private subnets in AZ 1a and 1b
resource "aws_subnet" "private_subnet_1a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private-subnet-1a"
  }
}

resource "aws_subnet" "private_subnet_1b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private-subnet-1b"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "my_internet_gateway" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-internet-gateway"
  }
}

# Attach internet gateway to public subnets
resource "aws_route_table" "public_route_table_1a" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_internet_gateway.id
  }

  tags = {
    Name = "public-route-table-1a"
  }
}

resource "aws_route_table" "public_route_table_1b" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_internet_gateway.id
  }

  tags = {
    Name = "public-route-table-1b"
  }
}

resource "aws_route_table_association" "public_subnet_1a_association" {
  subnet_id      = aws_subnet.public_subnet_1a.id
  route_table_id = aws_route_table.public_route_table_1a.id
}

resource "aws_route_table_association" "public_subnet_1b_association" {
  subnet_id      = aws_subnet.public_subnet_1b.id
  route_table_id = aws_route_table.public_route_table_1b.id
}

# Create a security group for the web servers
resource "aws_security_group" "web_server_sg" {
  name        = "web-server-sg"
  description = "Security group for web servers"

  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from any source
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

# Create a launch template for web servers
resource "aws_launch_template" "web_server_lt" {
  name          = "web-server-lt"
  image_id      = "ami-0c15992413464c248"
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_server_sg.id]
  }
}

# Create a data server in the private subnet
resource "aws_instance" "data_server" {
  ami           = "ami-04243397043fb84a6"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet_1a.id

  tags = {
    Name = "data-server"
  }
}

# Create an autoscaling group for the web servers
resource "aws_autoscaling_group" "web_server_asg" {
  name                 = "web-server-asg"
  min_size             = 1
  max_size             = 3

  vpc_zone_identifier  = [aws_subnet.public_subnet_1a.id, aws_subnet.public_subnet_1b.id]
  
  launch_template {
    id      = aws_launch_template.web_server_lt.id
    version = aws_launch_template.web_server_lt.latest_version
  }
}

# Create a target group for the load balancer
resource "aws_lb_target_group" "web_server_target_group" {
  name     = "web-server-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    path = "/"
  }
}

# Create a load balancer
resource "aws_lb" "web_server_lb" {
  name            = "web-server-lb"
  internal        = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.web_server_sg.id]
  subnets         = [aws_subnet.public_subnet_1a.id, aws_subnet.public_subnet_1b.id]

  tags = {
    Name = "web-server-lb"
  }
}

# Create a listener for the load balancer
resource "aws_lb_listener" "web_server_listener" {
  load_balancer_arn = aws_lb.web_server_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.web_server_target_group.arn
    type             = "forward"
  }
}

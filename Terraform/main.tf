# Creaete the S3 Bucket
resource "aws_s3_bucket" "bucket" {
  //bucket        = var.app_environment."-".s3_bucket_name
  bucket        = "${lower(var.app_name)}-${var.app_environment}-${var.s3_bucket_name}"
}

# Create the VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "${lower(var.app_name)}-${lower(var.app_environment)}-vpc"
    Environment = var.app_environment
  }
}

# Create the IAM Role
data "aws_iam_policy_document" "instance_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance_role" {
  name               = "instance_role_2"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.instance_role.json
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "instance_profile"
  role = aws_iam_role.instance_role.name
}

resource "aws_iam_role_policy" "s3_policy" {
  name = "s3_policy"
  role = aws_iam_role.instance_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:*",
          "s3-object-lambda:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Define the public subnets
resource "aws_subnet" "public-subnet" {
  //count             = aws_vpc.vpc == "10.11.0.0/16" ? 3 : 0
  count             = 3
  vpc_id            = aws_vpc.vpc.id
  //cidr_block        = var.public_subnet_cidr
  cidr_block        = element(cidrsubnets(var.vpc_cidr, 8, 4, 4), count.index)
  availability_zone = data.aws_availability_zones.azs.names[count.index]
  //availability_zone = var.aws_az

  tags = {
    Name = "${lower(var.app_name)}-${lower(var.app_environment)}-public-subnet"
    Environment = var.app_environment
  }
}

data "aws_availability_zones" "azs" {}

# Define the internet gateway
resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${lower(var.app_name)}-${lower(var.app_environment)}-igw"
    Environment = var.app_environment
  }
}

# Define the public route table
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway.id
  }
  tags = {
    Name = "${lower(var.app_name)}-${lower(var.app_environment)}-public-subnet-rt"
    Environment = var.app_environment
  }
}

# Assign the public route table to the public subnet
resource "aws_route_table_association" "public-rt-association" {
  count          = length(aws_subnet.public-subnet) == 3 ? 3 : 0
  //subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = element(aws_subnet.public-subnet.*.id, count.index)
}

# Get latest Ubuntu Linux Bionic Beaver 18.04 AMI
data "aws_ami" "ubuntu-linux-1804" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Define the security group for the Sserver
resource "aws_security_group" "aws-server-sg" {
  name        = "${lower(var.app_name)}-${var.app_environment}-sg"
  description = "Allow incoming HTTP connections"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming HTTP connections"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming SSH connections"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming HTTPS connections"
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming Custom TCP connections"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${lower(var.app_name)}-${var.app_environment}-sg"
    Environment = var.app_environment
  }
}

# Create EC2 Instance
resource "aws_instance" "ec2-server-shoppingcart" {
  //count                       = var.ec2_number_instance
  count                       = length(aws_subnet.public-subnet.*.id)
  //ami                         = data.aws_ami.ubuntu-linux-1804.id
  ami                         = "ami-0b0dcb5067f052a63"
  instance_type               = var.ec2_instance_type
  //subnet_id                 = aws_subnet.public-subnet.id
  subnet_id                   = element(aws_subnet.public-subnet.*.id, count.index)
  vpc_security_group_ids      = [aws_security_group.aws-server-sg.id]
  associate_public_ip_address = true
  source_dest_check           = false
  key_name                    = aws_key_pair.key_pair.key_name
  //user_data                   = file("aws-user-data.sh")
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  user_data                   = file("userdata.sh")

  # root disk
  root_block_device {
    volume_size           = var.ec2_root_volume_size
    volume_type           = var.ec2_root_volume_type
    delete_on_termination = true
    encrypted             = true
  }  # extra disk
  ebs_block_device {
    device_name           = "/dev/xvda"
    volume_size           = var.ec2_data_volume_size
    volume_type           = var.ec2_data_volume_type
    encrypted             = true
    delete_on_termination = true
  }
  
  tags = {
    Name        = "${lower(var.app_name)}-${var.app_environment}-${count.index}"
    Environment = var.app_environment
  }
}

//Create Target Group
resource "aws_lb_target_group" "tg" {
  name        = "TargetGroup"
  port        = 80
  target_type = "instance"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id

  health_check {
    path = "/"
    port = 80
  }
}

resource "aws_alb_target_group_attachment" "tgattachment" {
  count            = length(aws_instance.ec2-server-shoppingcart.*.id) == 3 ? 3 : 0
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = element(aws_instance.ec2-server-shoppingcart.*.id, count.index)
}

resource "aws_lb" "lb" {
  name               = "ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.aws-server-sg.id, ]
  subnets            = aws_subnet.public-subnet.*.id
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_listener_rule" "static" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn

  }

  condition {
    path_pattern {
      values = ["/var/www/html/index.html"]
    }
  }
}


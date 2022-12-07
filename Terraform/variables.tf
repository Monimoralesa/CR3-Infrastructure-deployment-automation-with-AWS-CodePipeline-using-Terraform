#
variable "region" {
  type    = string
}

variable "aws_az" {
  type        = string
  description = "AWS AZ"
}

variable dockerhub_credentials {
    type = string
}

variable codepipeline_connection_credentials {
    type = string
}

variable s3_bucket_name {
    type = string
}

# Subnet Variables
variable "app_name" {
  type  = string
}

# Subnet Variables
variable "app_environment" {
  type  = string
}

# VPC Variables
variable "vpc_cidr" {
  type  = string
}

# Subnet Variables
variable "public_subnet_cidr" {
  type  = string
}

# EC2 instance type
variable "ec2_instance_type" {
  type        = string
}

# EC2 number of instances
variable "ec2_number_instance" {
  type        = number
}

variable "ec2_associate_public_ip_address" {
  type        = bool
  description = "Associate a public IP address to the EC2 instance"
  default     = true
}

variable "ec2_root_volume_size" {
  type        = number
}

variable "ec2_root_volume_type" {
  type        = string
}

variable "ec2_data_volume_size" {
  type        = number
}

variable "ec2_data_volume_type" {
  type        = string
}

variable "iam_role_id" {
  type        = string
}

variable "key_pair_name" {
  type        = string
  description = "Key pair name"
  default     = "shopping_cart"
}



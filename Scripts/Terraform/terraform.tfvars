dockerhub_credentials = "arn:aws:secretsmanager:us-east-1:934221298434:secret:codebuild/dockerhub-a2Blu4"
codepipeline_connection_credentials = "arn:aws:codestar-connections:us-east-1:934221298434:connection/da1fb679-25ef-4156-a693-b80f27c18f7e"

region          = "us-east-1"
aws_az          = "us-east-1a"

# S3 Bucket
s3_bucket_name = "pipeline-cr3-jmonicam"

# Application Definition 
app_name        = "shopping-cart" # Do NOT enter any spaces
app_environment = "dev"       # Dev, Test, Staging, Prod, etc

# Network
vpc_cidr           = "10.11.0.0/16"
public_subnet_cidr = "10.11.1.0/24"

# IAM Role
iam_role_id = ""

#EC2
ec2_number_instance = 1
ec2_instance_type  = "t2.micro"
ec2_associate_public_ip_address = true
ec2_root_volume_size            = 20
ec2_root_volume_type            = "gp2"
ec2_data_volume_size            = 10
ec2_data_volume_type            = "gp2"
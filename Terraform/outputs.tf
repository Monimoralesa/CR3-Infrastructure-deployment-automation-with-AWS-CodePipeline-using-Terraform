output "vpc_id" {
  description = "ID of the vpc"
  value  = aws_vpc.vpc.id
}

output "aws_security_group" {
  description = "S3 Bucket arn"
  value  = [aws_security_group.aws-server-sg.id]
}


terraform {
  backend "s3" {
    bucket   = "aws-terrafrom-pipeline-cr3-base"
    key      = "stack_dev-base.tfstate"
    region   = "us-east-1"
  }
}
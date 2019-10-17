provider "aws" {
  version = "~> 1.0"
  region = "us-east-1"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 1.0"

  enable_nat_gateway  = true
  single_nat_gateway  = true
}

# SSM Variables - will be referenced in the serverless deployment
resource "aws_ssm_parameter" "default_sg" {
  name        = "/vpc/security_group/default"
  description = "Default security for the VPC - serverless uses this deploy lambdas to the VPC the sg belongs to"
  type        = "String"
  value       = "${module.vpc.default_security_group_id}"
  overwrite   = "true"
}

resource "aws_ssm_parameter" "private_subnets" {
  name        = "/vpc/subnets/private"
  type        = "StringList"
  value       = "${join(",", module.vpc.private_subnets)}"
  overwrite   = "true"
}

resource "aws_ssm_parameter" "elastic_ip" {
  name        = "/vpc/eip"
  type        = "String"
  value       = "${module.vpc.nat_public_ips[0]}"
  overwrite   = "true"
}

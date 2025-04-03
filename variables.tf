variable "project" {
    default = "devops-exercise"
}

variable "aws_region" {
  description = "AWS region to deploy to"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDRs for public subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDRs for private subnets"
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID to use for the EC2 instance"
  default     = "ami-0c94855ba95c71c99"
}

variable "key_name" {
  description = "Key pair name for SSH access to the EC2 instance"
  default     = "key_pair" # Replace with your key pair name
}

variable "enable_bastion" {
  description = "Enable bastion host"
  type        = bool
  default     = false
}
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "nomad-consul"
}

variable "owner" {
  description = "Owner tag for resources"
  type        = string
  default     = "devops-team"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH and access UIs"
  type        = string
  default     = "0.0.0.0/0"
}

variable "server_count" {
  description = "Number of Nomad/Consul server instances"
  type        = number
  default     = 3
}

variable "client_count" {
  description = "Number of Nomad client instances"
  type        = number
  default     = 2
}

variable "server_instance_type" {
  description = "EC2 instance type for servers"
  type        = string
  default     = "t3.medium"
}

variable "client_instance_type" {
  description = "EC2 instance type for clients"
  type        = string
  default     = "t3.medium"
}

variable "ssh_user" {
  description = "SSH user for Ansible"
  type        = string
  default     = "ubuntu"
}
variable "cidr_block" {
  default = "10.0.0.0/16" # we can override
  type = string
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c","us-east-1d", "us-east-1e", "us-east-1f"]
}

variable "enable_dns_hostnames" {
  default = true
  type = bool
}

variable "common_tags" {
  default = {}
}

variable "vpc_tags" {
  default = {}
}

variable "igt_tags" {
  default = {}
}

variable "nat_gt_tags" {
  default = {}
}

variable "public_subnet_tags" {
  default = {}
}

variable "private_subnet_tags" {
  default = {}
}

variable "public_route_table_tags" {
  default = {}
}

variable "private_route_table_tags" {
  default = {}
}

variable "peering_tags" {
  default = {}
}

variable "cidr_public" {
  type = list
}

variable "cidr_private" {
  type = list
}


variable "project_name" {
  type = string
}
variable "environment" {
  type = string
}

variable "acceptor_vpc_id" {
  type = string
}

variable "is_peering_required" {
  type = bool
}
## Terraform VPC module

This Terraform module creates a Virtual Private Cloud (VPC) suitable for a 3-tier application architecture across two Availability Zones (AZs). Additionally, it supports VPC peering based on user requirements. If the user specifies an acceptor VPC ID, the module will establish VPC peering with the provided VPC. Otherwise, it will create VPC peering with the default VPC.

## Steps

1. Create a Virtual Private Cloud (VPC).
2. Attach an Internet gateway to the VPC for external internet access.
3. Define and configure subnets within the VPC, dividing the IP address range.
4. Set up route tables to control traffic between subnets and to the internet.
5. Establish routes within the route tables to direct traffic appropriately.
6. Associate the route tables with their corresponding subnets to enable routing.
7. Allocate an Elastic IP address for static public IP assignment for NAT gateway.
8. Deploy a NAT gateway within one of the public subnets for outbound internet access from private subnets.
9. Associate the NAT gateway with the private subnets to facilitate internet connectivity for resources within them.
10. Establish a peering connection between VPCs to enable communication between them.
11. Configure routes within the route tables of each VPC to direct traffic through the peering connection as needed.

## Inputs
- project_name (required) - project name
- environment (required) - provide which environment 
- cidr_block (optional) - by default 10.0.0.0/16
- common_tags (optional) - better to provide
- vpc_tags, igt_tags,nat_gt_tags,public_subnet_tags,private_subnet_tags,database_subnet_tags,public_route_table_tags, private_route_table_tags,peering_tags  (optional) - better to provide
- cidr_public (required) -  User must provide 2 valid public subnets CIDR

- cidr_private (required) -  User must provide 2 valid private subnets CIDR


- is_peering_required  (optional) - default false
- accepters_vpc_id  (optional) - default value is default VPC ID


## outputs

- vpc_id =  VPC id
- private_subnet_ids = Private subnet IDs
- public_subnet_ids = Public subnet IDs

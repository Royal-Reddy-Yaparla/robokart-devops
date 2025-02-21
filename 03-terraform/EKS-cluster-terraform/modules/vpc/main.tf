resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
  # refer to instances by their hostname instead of their IP address
  enable_dns_hostnames = var.enable_dns_hostnames
  tags = merge(
    var.common_tags,
    var.vpc_tags,
    {
        Name = local.name
   }
  )
}

resource "aws_internet_gateway" "igt" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    var.common_tags,
    var.igt_tags,
    {
        Name = local.name
   }
  )
}

resource "aws_subnet" "public" {
    count = length(var.cidr_public)
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.cidr_public[count.index]
    map_public_ip_on_launch = true
    availability_zone = var.availability_zones[count.index]
    tags = merge(
    var.common_tags,
    var.public_subnet_tags,
    {
        Name = "${local.name}-public-${var.availability_zones[count.index]}"
   }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igt.id
  }


  tags = merge(
    var.common_tags,
    var.public_route_table_tags,
    {
        Name = "${local.name}-public"
   }
  )
}


resource "aws_route_table_association" "public_route" {
  count = length(var.cidr_public)
  subnet_id      = element(aws_subnet.public[*].id,count.index)
  route_table_id = aws_route_table.public.id
}  


resource "aws_eip" "eip" {
  domain   = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[0].id 

  tags = merge(
    var.common_tags,
    var.nat_gt_tags,
    {
        Name = "${local.name}-nat-gt"
   }
  )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igt]
}

resource "aws_subnet" "private" {
    count = length(var.cidr_private)
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.cidr_private[count.index]

    availability_zone = var.availability_zones[count.index]
    tags = merge(
    var.common_tags,
    var.private_subnet_tags,
    {
        Name = "${local.name}-private-${var.availability_zones[count.index]}"
   }
  )
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }


  tags = merge(
    var.common_tags,
    var.private_route_table_tags,
    {
        Name = "${local.name}-private"
   }
  )
}

resource "aws_route_table_association" "private_route" {
  count = length(var.cidr_private)
  subnet_id      = element(aws_subnet.private[*].id,count.index)
  route_table_id = aws_route_table.private.id
}  


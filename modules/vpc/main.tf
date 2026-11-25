# Build order: VPC -> subnets -> internet gateway -> NAT -> route tables -> NACLs
# Every block only uses things defined above it.

# Each tier gets its own /20 block; each subnet (one per AZ) is a /24 inside it.
# One block per tier lets each NACL rule name a whole tier with one CIDR.
locals {
  public_block = cidrsubnet(var.vpc_cidr, 4, 0) # 10.0.0.0/20  -> 10.0.0.0/24, 10.0.1.0/24
  app_block    = cidrsubnet(var.vpc_cidr, 4, 1) # 10.0.16.0/20 -> 10.0.16.0/24, 10.0.17.0/24
  db_block     = cidrsubnet(var.vpc_cidr, 4, 2) # 10.0.32.0/20 -> 10.0.32.0/24, 10.0.33.0/24
}


# 1. VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "school-vpc"
  }
}

# 2. Subnets: 3 tiers x 2 AZs
# Public: ALB + NAT gateway
resource "aws_subnet" "public" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.azs[count.index]
  cidr_block              = cidrsubnet(local.public_block, 4, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name = "public-${var.azs[count.index]}"
  }
}

# Private app: WordPress EC2 (no public IP, internet only through NAT)
resource "aws_subnet" "private_app" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.main.id
  availability_zone = var.azs[count.index]
  cidr_block        = cidrsubnet(local.app_block, 4, count.index)

  tags = {
    Name = "private-app-${var.azs[count.index]}"
  }
}

# Private DB: RDS (no internet at all)
resource "aws_subnet" "private_db" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.main.id
  availability_zone = var.azs[count.index]
  cidr_block        = cidrsubnet(local.db_block, 4, count.index)

  tags = {
    Name = "private-db-${var.azs[count.index]}"
  }
}


# 3. Internet gateway: the VPC's door to the internet (used by public subnets)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "school-igw"
  }
}


# 4. NAT gateway: lets private EC2 go out (dnf, wordpress.org, Secrets Manager)
#    without anyone coming in. One NAT to save cost; production: one per AZ.
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "school-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "school-nat"
  }
}


# 5. Route tables: where each tier's traffic to 0.0.0.0/0 goes
# Public -> internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private app -> NAT gateway
resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-app-rt"
  }
}

resource "aws_route_table_association" "private_app" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app.id
}

# Private DB -> no 0.0.0.0/0 route: only traffic inside the VPC
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-db-rt"
  }
}

resource "aws_route_table_association" "private_db" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db.id
}


# 6. Network ACLs: subnet-level firewall, the second layer behind security groups.
#    NACLs are STATELESS: replies are not allowed automatically, so every tier also
#    allows ephemeral ports 1024-65535 for return traffic.

# Public NACL (ALB + NAT)
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  # HTTPS from CloudFront (NACLs can't use prefix lists; the ALB security group narrows it)
  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
  }

  # HTTP from the app tier, going out through the NAT
  ingress {
    rule_no    = 110
    action     = "allow"
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = local.app_block
  }

  # Replies: from EC2 to the ALB, and from the internet to the NAT
  ingress {
    rule_no    = 120
    action     = "allow"
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
  }

  # HTTP to EC2 (ALB) and to the internet (NAT)
  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
  }

  # HTTPS to the internet (NAT)
  egress {
    rule_no    = 110
    action     = "allow"
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
  }

  # Replies: to CloudFront, and back to EC2 through the NAT
  egress {
    rule_no    = 120
    action     = "allow"
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "public-nacl"
  }
}

# Private app NACL (EC2)
resource "aws_network_acl" "private_app" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private_app[*].id

  # HTTP from the ALB only
  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = local.public_block
  }

  # Replies: from the internet (through NAT) and from RDS
  ingress {
    rule_no    = 110
    action     = "allow"
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
  }

  # HTTP and HTTPS out through the NAT
  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
  }

  egress {
    rule_no    = 110
    action     = "allow"
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
  }

  # MySQL to the DB tier only
  egress {
    rule_no    = 120
    action     = "allow"
    protocol   = "tcp"
    from_port  = 3306
    to_port    = 3306
    cidr_block = local.db_block
  }

  # Replies to the ALB
  egress {
    rule_no    = 130
    action     = "allow"
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = local.public_block
  }

  tags = {
    Name = "private-app-nacl"
  }
}

# Private DB NACL (RDS): only MySQL from the app tier, and the replies
resource "aws_network_acl" "private_db" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private_db[*].id

  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    from_port  = 3306
    to_port    = 3306
    cidr_block = local.app_block
  }

  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = local.app_block
  }

  tags = {
    Name = "private-db-nacl"
  }
}

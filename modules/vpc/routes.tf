# -----------------------------------------------------------------------
#                           public route tables
# -----------------------------------------------------------------------

# Single route table for all public subnets (with route to Internet Gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Route for internet access through Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.name}-public-rt"
    Type = "public"
  }
}

# Binding public subnets to the public route table
resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# -----------------------------------------------------------------------
#                           private route tables
# -----------------------------------------------------------------------
# Separate table for each private subnet (each uses its own NAT Gateway)
resource "aws_route_table" "private" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.main.id

  # Route through NAT Gateway for internet access
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.name}-private-rt-${count.index + 1}"
    Type = "private"
  }
}

# Binding private subnets to the corresponding route tables
resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_vpc" "vpc" {
  cidr_block = var.network_address_space

  tags = { Name = "${var.app_tag}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = { Name = "${var.app_tag}-igw" }

}

resource "aws_subnet" "subnet1" {
  cidr_block              = var.subnet1_address_space
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = { Name = "${var.app_tag}-subnet1" }

}

resource "aws_subnet" "subnet2" {
  cidr_block              = var.subnet2_address_space
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = { Name = "${var.app_tag}-subnet2" }

}

resource "aws_db_subnet_group" "default" {
  name       = "${var.app_tag}_subnet_group"
  subnet_ids = ["${aws_subnet.subnet1.id}", "${aws_subnet.subnet2.id}"]
}

# ROUTING #
resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "${var.app_tag}-rtb" }

}

resource "aws_route_table_association" "rta-subnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rtb.id
}

resource "aws_route_table_association" "rta-subnet2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.rtb.id
}
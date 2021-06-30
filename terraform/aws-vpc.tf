#
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
resource "aws_vpc" "k8s-cluster" {
  cidr_block = "${var.cidr_block_prefix}.0.0/16"

  tags = tomap({
      "Name": "${var.env}-vpc",
      "kubernetes.io/cluster/${var.env}-eks-cluster": "shared",
    })
}

resource "aws_subnet" "k8s-cluster" {
  count = 2

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = "${var.cidr_block_prefix}.${count.index}.0/24"
  vpc_id            = aws_vpc.k8s-cluster.id

  tags = tomap({
      "Name": "${var.env}-eks-subnet-${count.index}",
      "kubernetes.io/cluster/${var.env}-eks-cluster": "shared",
    })
}

resource "aws_internet_gateway" "k8s-cluster" {
  vpc_id = aws_vpc.k8s-cluster.id

  tags = {
    Name = "${var.env}-eks-igw"
  }
}

resource "aws_route_table" "k8s-cluster" {
  vpc_id = aws_vpc.k8s-cluster.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s-cluster.id
  }
}

resource "aws_route_table_association" "k8s-cluster" {
  count = 2

  subnet_id      = aws_subnet.k8s-cluster.*.id[count.index]
  route_table_id = aws_route_table.k8s-cluster.id
}
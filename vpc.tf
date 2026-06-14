provider "aws" {
    region = var.chosenregion
}

resource "aws_vpc" "myvpc" {
    cidr_block = "10.1.0.0/16"
    enable_dns_hostnames = true
}

data "aws_availability_zones" "available" {
    state = "available"
}

resource "aws_subnet" "pubsub1" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.1.11.0/24"
    availability_zone = data.aws_availability_zones.available.names[0]
    map_public_ip_on_launch = true
}

resource "aws_subnet" "pubsub2" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.1.12.0/24"
    availability_zone = data.aws_availability_zones.available.names[1]
    map_public_ip_on_launch = true
}

resource "aws_subnet" "privsub1" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.1.21.0/24"
    availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "privsub2" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.1.22.0/24"
    availability_zone = data.aws_availability_zones.available.names[1]
}

resource "aws_internet_gateway" "myigw" {
    vpc_id = aws_vpc.myvpc.id
}

resource "aws_eip" "myeip1" {
    domain = "vpc"
}

resource "aws_eip" "myeip2" {
    domain = "vpc"
}

resource "aws_nat_gateway" "mynat1" {
    allocation_id = aws_eip.myeip1.id
    subnet_id = aws_subnet.pubsub1.id
}

resource "aws_nat_gateway" "mynat2" {
    allocation_id = aws_eip.myeip2.id
    subnet_id = aws_subnet.pubsub2.id
}

resource "aws_route_table" "pubrt" {
    vpc_id = aws_vpc.myvpc.id
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myigw.id
    }
}

resource "aws_route_table" "privrt1" {
    vpc_id = aws_vpc.myvpc.id
    route{
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.mynat1.id
    }
}

resource "aws_route_table" "privrt2" {
    vpc_id = aws_vpc.myvpc.id
    route{
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.mynat2.id
    }
}

resource "aws_route_table_association" "privaso1" {
    subnet_id = aws_subnet.privsub1.id
    route_table_id = aws_route_table.privrt1.id
}

resource "aws_route_table_association" "privaso2" {
    subnet_id = aws_subnet.privsub2.id
    route_table_id = aws_route_table.privrt2.id
}

resource "aws_route_table_association" "pubaso1" {
    subnet_id = aws_subnet.pubsub1.id
    route_table_id = aws_route_table.pubrt.id
}

resource "aws_route_table_association" "pubaso2" {
    subnet_id = aws_subnet.pubsub2.id
    route_table_id = aws_route_table.pubrt.id
}


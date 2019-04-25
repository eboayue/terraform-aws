# Initialization
provider "aws" {
	 region = "${var.region}"
	 access_key = "${var.access_key}"
	 secret_key = "${var.secret_key}"
}


# VPC and subnet creation
resource "aws_vpc" "vpc1" {
	 cidr_block = "10.100.0.0/16"

	 tags = {
	      Name = "vpc1"
	      }
}

resource "aws_subnet" "public" {
	 vpc_id = "${aws_vpc.vpc1.id}"
	 cidr_block = "10.100.1.0/24"
	 availability_zone = "us-west-2a"
	 map_public_ip_on_launch = "true"

	 tags = {
	      Name = "public"
	      }
}

resource "aws_subnet" "private" {
	 vpc_id = "${aws_vpc.vpc1.id}"
	 cidr_block = "10.100.9.0/24"

	 tags = {
	      Name = "private"
	      }
}

resource "aws_subnet" "secondary" {
	 vpc_id = "${aws_vpc.vpc1.id}"
	 cidr_block = "10.100.5.0/24"
	 availability_zone = "us-west-2c"
	 map_public_ip_on_launch = "true"
	 tags = {
	      Name = "secondary"
	      }
}


# Internet gateway creation
resource "aws_internet_gateway" "gateway1" {
	 vpc_id = "${aws_vpc.vpc1.id}"

	 tags = {
	      Name = "gateway1"
	      }
}

# Route table creation and association
resource "aws_route_table" "routetable1" {
	 vpc_id = "${aws_vpc.vpc1.id}"

	 route {
	       cidr_block = "0.0.0.0/0"
	       gateway_id = "${aws_internet_gateway.gateway1.id}"
	       }

	 tags {
	      Name = "routetable1"
	      }
}

resource "aws_route_table_association" "association1"{
	 subnet_id = "${aws_subnet.public.id}"
	 route_table_id = "${aws_route_table.routetable1.id}"
}

resource "aws_route_table_association" "association2"{
	 subnet_id = "${aws_subnet.secondary.id}"
	 route_table_id = "${aws_route_table.routetable1.id}"
}

# Security Group creation
resource "aws_security_group" "Web" {
	 name = "Web"
	 description = "Allow ssh and web traffic"
	 vpc_id = "${aws_vpc.vpc1.id}"

	 ingress {
	 	 from_port = 22
	 	 to_port = 22
		 protocol = "tcp"
		 cidr_blocks = ["0.0.0.0/0"]
		 }

	 ingress {
	 	 from_port = 80
	 	 to_port = 80
		 protocol = "tcp"
		 cidr_blocks = ["0.0.0.0/0"]
		 }

	 ingress {
	 	 from_port = 443
	 	 to_port = 443
		 protocol = "tcp"
		 cidr_blocks = ["0.0.0.0/0"]
		 }

	 egress {
	 	 from_port = 0
	 	 to_port = 0
		 protocol = "-1"
		 cidr_blocks = ["0.0.0.0/0"]
		 }
}

# EC2 instance creation
resource "aws_instance" "first" {
	 ami = "ami-08692d171e3cf02d6"
	 instance_type = "t2.micro"
	 security_groups = ["${aws_security_group.Web.id}"]
	 subnet_id = "${aws_subnet.public.id}"
	 key_name = "TwitchServer"
	 tags {
	      Name = "first"
	      }
}

# Initialization
provider "aws" {
	 region = "${var.region}"
	 access_key = "${var.access_key}"
	 secret_key = "${var.secret_key}"
}


# VPC and subne creation
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

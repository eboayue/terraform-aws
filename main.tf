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


# Create Launch configuration
resource "aws_launch_configuration" "TwitchConfig" {
	name_prefix = "TwitchConfig-"
	image_id = "ami-08692d171e3cf02d6"
	instance_type = "t2.micro"
	key_name = "TwitchServer"
	security_groups = ["${aws_security_group.Web.id}"]
	iam_instance_profile = "${aws_iam_instance_profile.logoprofile.name}"

	user_data = "${file("instance-setup.sh")}"
	lifecycle {
		create_before_destroy = true
		}
}

# Create Autoscaling group
resource "aws_autoscaling_group" "Web_ASG" {
	name = "Web_ASG"
	launch_configuration = "${aws_launch_configuration.TwitchConfig.name}"
	min_size = 2
	max_size = 2
	vpc_zone_identifier = ["${aws_subnet.public.id}", "${aws_subnet.secondary.id}"]
	target_group_arns = ["${aws_lb_target_group.TwitchTG.arn}"]

	lifecycle {
		create_before_destroy = true
		}
}

# Create Load balancer
resource "aws_lb" "TwitchLB" {
	name = "TwitchLB"
	load_balancer_type = "application"
	security_groups = ["${aws_security_group.Web.id}"]
	subnets = ["${aws_subnet.public.id}", "${aws_subnet.secondary.id}"]
}

# Create target group
resource "aws_lb_target_group" "TwitchTG" {
	name = "TwitchTG"
	port = 80
	protocol = "HTTP"
	vpc_id = "${aws_vpc.vpc1.id}"

	health_check {
		port = 80
		}
}

# Create Listener
resource "aws_lb_listener" "TwitchTGlisten" {
	load_balancer_arn = "${aws_lb.TwitchLB.arn}"
	port = 80
	protocol = "HTTP"

	default_action {
		type = "forward"
		target_group_arn = "${aws_lb_target_group.TwitchTG.arn}"
		}
}

# Create S3 bucket and store logo in it
resource "aws_s3_bucket" "twitchlogo" {
	bucket = "twitchlogo"
}

resource "aws_s3_bucket_object" "logo" {
	bucket = "${aws_s3_bucket.twitchlogo.id}"
	key = "Twitch_logo.jpg"
	source = "./Twitch_logo.jpg"
}

# Create policy and IAM role to allow EC2 instances to access contents of
# previously created bucket
data "aws_iam_policy_document" "logodata" {
	statement {
		effect = "Allow"
		actions = [
			"s3:ListBucketByTags",
			"s3:GetLifecycleConfiguration",
			"s3:GetBucketTagging",
			"s3:GetInventoryConfiguration",
			"s3:GetObjectVersionTagging",
			"s3:ListBucketVersions",
			"s3:GetBucketLogging",
			"s3:GetAccelerateConfiguration",
			"s3:GetBucketPolicy",
			"s3:GetObjectVersionTorrent",
			"s3:GetObjectAcl",
			"s3:GetEncryptionConfiguration",
			"s3:GetBucketRequestPayment",
			"s3:GetObjectVersionAcl",
			"s3:GetObjectTagging",
			"s3:GetMetricsConfiguration",
			"s3:GetBucketPublicAccessBlock",
			"s3:GetBucketPolicyStatus",
			"s3:ListBucketMultipartUploads",
			"s3:GetBucketWebsite",
			"s3:GetBucketVersioning",
			"s3:GetBucketAcl",
			"s3:GetBucketNotification",
			"s3:GetReplicationConfiguration",
			"s3:ListMultipartUploadParts",
			"s3:GetObject",
			"s3:GetObjectTorrent",
			"s3:GetBucketCORS",
			"s3:GetAnalyticsConfiguration",
			"s3:GetObjectVersionForReplication",
			"s3:GetBucketLocation",
			"s3:GetObjectVersion",
			"s3:ListBucket"
			]
		resources = [
			"arn:aws:s3:::twitchlogo",
			"arn:aws:s3:::twitchlogo/*"
			]
		}

	statement {
		effect = "Allow"
		actions = [
		"s3:GetAccountPublicAccessBlock",
		"s3:ListAllMyBuckets",
		"s3:HeadBucket"
		]
		resources = [ "*"]
	}
}

resource "aws_iam_policy" "logobucketpolicy" {
	name = "logobucketpolicy"
	description = "allows list and read access to s3 bucket twitchlogo"
	policy = "${data.aws_iam_policy_document.logodata.json}"
}

data "aws_iam_policy_document" "roledata" {
	statement {
		actions = ["sts:AssumeRole"]
		principals {
			type = "Service"
			identifiers = ["ec2.amazonaws.com"]
		}
		effect = "Allow"
	}
}

resource "aws_iam_role" "logoaccess" {
	name = "logoaccess"
	assume_role_policy = "${data.aws_iam_policy_document.roledata.json}"
}

resource "aws_iam_role_policy_attachment" "logoattach" {
	role = "${aws_iam_role.logoaccess.name}"
	policy_arn = "${aws_iam_policy.logobucketpolicy.arn}"
}

resource "aws_iam_instance_profile" "logoprofile" {
	name = "logoprofile"
	role = "${aws_iam_role.logoaccess.name}"
}

resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
}
resource "aws_subnet" "sub1" {
  vpc_id = aws_vpc.myvpc.id
  availability_zone = var.az1
    cidr_block = var.cidrsub1
    map_public_ip_on_launch = true
}

resource "aws_subnet" "sub2" {
  vpc_id = aws_vpc.myvpc.id
  availability_zone = var.az2
    cidr_block = var.cidrsub2
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "RT" {
    vpc_id = aws_vpc.myvpc.id

    route {
    cidr_block = var.cidrblk #so that evrything in vpc gets connected to IG(target)
    gateway_id = aws_internet_gateway.myigw.id #destination
    }
}

resource "aws_route_table_association" "RTA1" {
     subnet_id = aws_subnet.sub1.id
     route_table_id = aws_route_table.RT.id
}

resource "aws_route_table_association" "RTA2" {
     subnet_id = aws_subnet.sub2.id
     route_table_id = aws_route_table.RT.id
}

resource "aws_security_group" "websg" {
  name        = "web-sg"
  description = "Allow all inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "HTTP"
    from_port   = var.porthttp # Using port 80 because we don't have SSL configured as of now, with SSL you can go with port 443 i.e. is HTTPS
    to_port     = var.porthttp
    protocol    = var.protocolvar
    cidr_blocks = [var.cidrblk] # To allow traffic from evrywhere
  }
  ingress {
    description = "SSH"
    from_port   = 22 # Using port 22 for SSH
    to_port     = 22
    protocol    = var.protocolvar
    cidr_blocks = [var.cidrblk] # To allow traffic from evrywhere
  }

  egress {
    from_port   = 0  # 0 means all IPs are allowed here
    to_port     = 0  # 0 means all IPs are allowed here
    protocol    = "-1"
    cidr_blocks = [var.cidr] #To hit all traffic all IPs
}

  tags = {
    Name = "WEB-SG"
  }
}

resource "aws_s3_bucket" "example" {
  bucket = "s3bucketterraformwithawsmansi"

}
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example,
  ]

  bucket = aws_s3_bucket.example.id
  acl    = "public-read"
}

resource "aws_instance" "webserver1" {
  ami           = var.amival
  instance_type = var.instancetype
  vpc_security_group_ids = [aws_security_group.websg.id]
  subnet_id = aws_subnet.sub1.id
  user_data = base64encode(file("userdata1.sh")) #using file element for user data and encoding it using base64
}

resource "aws_instance" "webserver2" {
  ami           = var.amival
  instance_type = var.instancetype
  vpc_security_group_ids = [aws_security_group.websg.id]
  subnet_id = aws_subnet.sub2.id
  user_data   = base64encode(file("userdata2.sh")) #using file element for user data and encoding it using base64
}


#creating application load balancer
resource "aws_lb" "myalb" {
  name               = "myalb"
  internal           = false #which means it is not internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.websg.id]
  subnets            = [aws_subnet.sub1.id,aws_subnet.sub2.id]

  tags = {
    Environment = "web"
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "my-tg"
  port     = var.porthttp
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}
#we need to define what is there inside target group
#we will attach load balancer to target group
resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver1.id
  port             = var.porthttp
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver2.id
  port             = var.porthttp
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.myalb.arn
  port = var.porthttp
  protocol = "HTTP"

 default_action {
   target_group_arn = aws_lb_target_group.tg.arn
   type = "forward" #forward action for listener
 }
}

output "loadbalancerdns" {
  value = aws_lb.myalb.dns_name
}

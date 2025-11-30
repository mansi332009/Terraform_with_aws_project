variable "cidr" {
  default = "10.0.0.0/16"
}

variable "cidrsub1" {
  default = "10.0.0.0/24"
}

variable "az1" {
  default = "us-east-1a"
}

variable "cidrsub2" {
  default = "10.0.1.0/24"
}

variable "az2" {
  default = "us-east-1b"
}

variable "cidrblk" {
  default = "0.0.0.0/0"
}

variable "amival" {
  default = "ami-0c398cb65a93047f2"
}

variable "instancetype" {
  default = "t2.micro"
}

variable "protocolvar" {
  default = "tcp"
}

variable "porthttp" {
  default = 80
}

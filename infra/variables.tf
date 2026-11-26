variable "aws_region" {
  default = "us-east-1"
}

variable "availability_zones" {
  type = list(string)
  description = "List of azs to use for vpc"
  default = [ "us-east-1a", "us-east-1b", "us-east-1c" ]
}
variable "key_name" {
  type = string
  default = "sonarkey"
}

variable "instance_type" {
  type = string
  default = "t2.xlarge"
}
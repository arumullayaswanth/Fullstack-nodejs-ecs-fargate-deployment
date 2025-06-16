

provider "aws" {
    region = "us-east-1"
  
}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["ecs-vpc"]
  }
}

data "aws_subnet" "private1" {
  filter {
    name   = "tag:Name"
    values = ["ecs-private1"]
  }
}

data "aws_subnet" "private2" {
  filter {
    name   = "tag:Name"
    values = ["ecs-private2"]
  }
}

data "aws_security_group" "sg" {
  filter {
    name   = "tag:Name"
    values = ["lb-sg"]
  }
}

data "aws_subnet" "public1" {
  filter {
    name   = "tag:Name"
    values = ["ecs-public1"]
  }
}

data "aws_subnet" "public2" {
  filter {
    name   = "tag:Name"
    values = ["ecs-public2"]
  }
}

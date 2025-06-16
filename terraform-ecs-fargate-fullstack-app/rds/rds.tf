

provider "aws" {
    region = "us-east-1"
  
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



resource "aws_db_instance" "rds" {
  allocated_storage      = 20
  identifier = "book-rds"
  db_subnet_group_name   = aws_db_subnet_group.sub-grp.id
  engine                 = "mysql"
  engine_version         = "8.0.32"
  instance_class         = "db.t3.micro"
  multi_az               = true
  db_name                = "mydb"
  username               = "admin"
  password               = "Yaswanth123reddy"
  skip_final_snapshot    = true
  vpc_security_group_ids = [data.aws_security_group.sg.id]
  depends_on = [ aws_db_subnet_group.sub-grp ]
  publicly_accessible = true
  backup_retention_period = 7

  
  tags = {
    DB_identifier = "book-rds"
  }
}

resource "aws_db_subnet_group" "sub-grp" {
  name       = "rds"
  subnet_ids = [data.aws_subnet.private1.id, data.aws_subnet.private2.id]

  tags = {
    Name = "My-DB-subnet-group"
  }
}


output "rds_address" {
  value = aws_db_instance.rds.address
}

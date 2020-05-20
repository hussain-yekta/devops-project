resource "aws_db_instance" "myDB" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "admin"
  password             = "vnksnvdjnskdnvkjsdndvsds"
  parameter_group_name = "default.mysql5.7"
  backup_retention_period = 7
}

output "myDB" {
  value = "${aws_db_instance.myDB.endpoint}"
}

resource "aws_db_subnet_group" "dbsub" {
    name = "rdssubnet"
    subnet_ids = [aws_subnet.privsub1.id, aws_subnet.privsub2.id]
}

resource "aws_db_instance" "mydb" {
    allocated_storage = 20
    engine = "mysql"
    engine_version = "8.0"
    instance_class = "db.t3.micro"
    db_name = "wordpressdb"
    username = "admin"
    password = var.db_password
    skip_final_snapshot = true
    multi_az = var.chosentype == "PRODUCTION" ? true : false
    db_subnet_group_name = aws_db_subnet_group.dbsub.name
    vpc_security_group_ids = [aws_security_group.datasg.id]
}

resource "aws_efs_file_system" "myefs" {
    creation_token = "wordpressefs"
}

resource "aws_efs_mount_target" "efsmt1" {
    file_system_id = aws_efs_file_system.myefs.id
    subnet_id = aws_subnet.privsub1.id
    security_groups = [aws_security_group.datasg.id]
}

resource "aws_efs_mount_target" "efsmt2" {
    file_system_id = aws_efs_file_system.myefs.id
    subnet_id = aws_subnet.privsub2.id
    security_groups = [aws_security_group.datasg.id]
}
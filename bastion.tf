resource "aws_instance" "bastion" {
    ami = data.aws_ssm_parameter.ecs_ami.value
    instance_type = "t3.micro"
    subnet_id = aws_subnet.pubsub1.id
    vpc_security_group_ids = [aws_security_group.bastionsg.id]
    key_name = "vockey"
    associate_public_ip_address = true
    tags = {name = "wordpress-bastion"}
    user_data_base64 = base64encode(templatefile("${path.module}/create_db.sh.tpl", {
        db_host     = aws_db_instance.mydb.address
        db_user     = aws_db_instance.mydb.username
        db_password = aws_db_instance.mydb.password
        wp_services = keys(local.wp_services)
    }))

    depends_on = [aws_db_instance.mydb]
}
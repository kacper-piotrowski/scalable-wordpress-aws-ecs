resource "aws_security_group" "lbsg" {
    name = "loadbalancersg"
    vpc_id = aws_vpc.myvpc.id
    dynamic "ingress" {
        for_each = [8081, 8082]
        content {
          from_port = ingress.value
          to_port = ingress.value
          protocol = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "bastionsg"{
    name = "bastionhostsg"
    vpc_id = aws_vpc.myvpc.id
    ingress{
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "wpsg"{
    name = "wordpresssg"
    vpc_id = aws_vpc.myvpc.id
    ingress{
        from_port = 32768
        to_port = 65535
        protocol = "tcp"
        security_groups = [aws_security_group.lbsg.id]
    }
    ingress{
        from_port = 22
        to_port = 22
        protocol = "tcp"
        security_groups = [aws_security_group.bastionsg.id]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        security_groups = [aws_security_group.bastionsg.id]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "datasg"{
    name = "RDS-EFSsg"
    vpc_id = aws_vpc.myvpc.id
    ingress{
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.wpsg.id]
    }
    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.bastionsg.id]
    }
    ingress {
        from_port = 2049
        to_port = 2049
        protocol = "tcp"
        security_groups = [aws_security_group.wpsg.id]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
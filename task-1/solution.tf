data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
}

resource "aws_instance" "web_servers" {
  count                       = 2
  instance_type               = "t2.micro"
  ami                         = "${data.aws_ami.amazon_linux.id}"
  associate_public_ip_address = true
  availability_zone = "ap-south-1b"
  user_data = "${file("user-data.txt")}"
  ebs_block_device {
    device_name           = "/dev/sdg"
    volume_type           = "gp2"
    volume_size           = 100
    delete_on_termination = false
  }
  key_name = "elb"

  tags {
    Name = "web-server"
  }
}


resource "aws_elb" "web_server_lb" {
  "listener" {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  availability_zones = ["ap-south-1b"]
  depends_on = ["aws_instance.web_servers"]

}

resource "aws_elb_attachment" "attach_ec2_to_elb" {
  elb = "${aws_elb.web_server_lb.id}"
  #instance = "${format("$${aws_instance.web_servers.%d.id}",count.index)}"
  instance = "${element(concat(aws_instance.web_servers.*.id, list("")), 1)}"
  depends_on = ["aws_instance.web_servers"]
}
resource "aws_elb_attachment" "attach_ec2_to_elb_second_instance" {
  elb = "${aws_elb.web_server_lb.id}"
  instance = "${element(concat(aws_instance.web_servers.*.id, list("")), 0)}"
  depends_on = ["aws_instance.web_servers"]
}


output "aws_lb" {
  value = "${aws_elb.web_server_lb.dns_name}"
}

output "data-disk_attached_to_this_server" {
  //value = "${aws_instance.web_servers.1.public_ip}"
  value = "${element(concat(aws_instance.web_servers.*.public_ip, list("")), 1)}"

}
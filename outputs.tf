output "public_ip" {
  description = "EC2 Public IP"

  value = aws_instance.zuriapp_server.public_ip
}

output "instance_id" {
  description = "EC2 Instance ID"

  value = aws_instance.zuriapp_server.id
}
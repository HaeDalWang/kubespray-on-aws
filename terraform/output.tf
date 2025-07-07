# kubespray 인스턴스 접속 정보
output "kubespray_access" {
  description = "kubespray 인스턴스 접속 정보"
  value = {
    public_ip   = aws_instance.public_ec2_instances[0].public_ip
    private_ip  = aws_instance.public_ec2_instances[0].private_ip
    public_dns  = aws_instance.public_ec2_instances[0].public_dns
    ssh_command = "ssh -i ~/.ssh/${var.ec2_keypair_name}.pem ubuntu@${aws_instance.public_ec2_instances[0].public_ip}"
  }
}
# ubuntu 22.04 AMI를 지정
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# local의 인스턴스 항목에 따라 ec2를 생성
resource "aws_instance" "ec2_instances" {
  for_each = { for idx, name in local.instance_names : idx => name }

  ami           = data.aws_ami.ubuntu.id
  instance_type = each.key == "kubespray" ? "t3a.small" : "t3a.medium"
  key_name      = var.ec2_keypair_name
  subnet_id     = each.key < 3 ? module.vpc.public_subnets[each.key] : module.vpc.private_subnets[each.key - 3]

  associate_public_ip_address = each.key < 3

  tags = {
    Name = each.value
  }
}
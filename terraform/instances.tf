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

# Public_Subnet에 존재해야할 Instance 항목
resource "aws_instance" "public_ec2_instances" {
  for_each = { for idx, name in local.public_instance_names : idx => name }

  ami           = data.aws_ami.ubuntu.id
  instance_type = each.key == "kubespray" ? "t3.small" : "t3.medium"
  key_name      = var.ec2_keypair_name

  subnet_id     = module.vpc.public_subnets[each.key % 4]
  associate_public_ip_address = true

  tags = {
    Name = each.value
  }
}

# Private_Subnet에 존재해야할 Instance 항목
resource "aws_instance" "private_ec2_instances" {
  for_each = { for idx, name in local.private_instance_names : idx => name }

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  key_name      = var.ec2_keypair_name

  subnet_id     = module.vpc.private_subnets[each.key % 4]

  tags = {
    Name = each.value
  }
}
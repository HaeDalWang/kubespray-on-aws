# 인스턴스 목록
locals {
  private_instance_names = [
    "master-1",
    "master-2",
    "master-3",
    "worker-1",
    "worker-2"
  ]
  public_instance_names = [
    "kubespray",
    "ingress-1",
    "ingress-2"  
  ]
  
  # Private IP 매핑
  private_ips = {
    0 = "172.22.10.10"  # master-1
    1 = "172.22.10.11"  # master-2
    2 = "172.22.10.12"  # master-3
    3 = "172.22.10.20"  # worker-1
    4 = "172.22.10.21"  # worker-2
  }
  
  public_ips = {
    0 = "172.22.0.10"   # kubespray
    1 = "172.22.0.11"   # ingress-1
    2 = "172.22.0.12"   # ingress-2
  }
}

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

  subnet_id     = module.vpc.public_subnets[0]  # 첫 번째 public 서브넷 사용
  private_ip    = local.public_ips[each.key]    # 고정 private IP 할당
  associate_public_ip_address = true

  # Public 인스턴스는 공통 보안 그룹 + Public 전용 보안 그룹 사용
  vpc_security_group_ids = [
    aws_security_group.kubespray_common.id,
    aws_security_group.kubespray_public.id
  ]

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

  subnet_id     = module.vpc.private_subnets[0]  # 첫 번째 private 서브넷 사용
  private_ip    = local.private_ips[each.key]    # 고정 private IP 할당

  # Private 인스턴스는 공통 보안 그룹만 사용
  vpc_security_group_ids = [
    aws_security_group.kubespray_common.id
  ]

  tags = {
    Name = each.value
  }
}
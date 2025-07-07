# Kubespray 공통 보안 그룹 (모든 인스턴스 사용)
resource "aws_security_group" "kubespray_common" {
  name        = "${local.project}-common"
  description = "Security group for kubespray installation - common rules"
  vpc_id      = module.vpc.vpc_id

  # SSH 접근 (22) - 내부 통신
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "SSH access from VPC"
  }

  # Kubernetes API server (6443)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Kubernetes API server"
  }

  # etcd server client API (2379-2380)
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "etcd server client API"
  }

  # kubelet API (10250)
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "kubelet API"
  }

  # kube-scheduler (10251)
  ingress {
    from_port   = 10251
    to_port     = 10251
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "kube-scheduler"
  }

  # kube-controller-manager (10252)
  ingress {
    from_port   = 10252
    to_port     = 10252
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "kube-controller-manager"
  }

  # Read-only kubelet API (10255)
  ingress {
    from_port   = 10255
    to_port     = 10255
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Read-only kubelet API"
  }

  # NodePort Services (30000-32767)
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "NodePort Services"
  }

  # Calico BGP (179) - 네트워크 플러그인용
  ingress {
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Calico BGP"
  }

  # Calico IP-in-IP (4) - 네트워크 플러그인용
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "4"
    cidr_blocks = [var.vpc_cidr]
    description = "Calico IP-in-IP"
  }

  # Flannel VXLAN (8472) - 네트워크 플러그인용
  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "Flannel VXLAN"
  }

  # 모든 아웃바운드 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${local.project}-common"
  }
}

# Public 인스턴스용 추가 보안 그룹
resource "aws_security_group" "kubespray_public" {
  name        = "${local.project}-public"
  description = "Security group for public instances - HTTP/HTTPS access"
  vpc_id      = module.vpc.vpc_id

  # HTTP 접근 (80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access from internet"
  }

  # HTTPS 접근 (443)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access from internet"
  }

  # SSH 접근 (22) - 외부에서 접근 (kubespray 인스턴스 관리용), 추후 자신의 IP로 변경하세요
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access from internet"
  }

  tags = {
    Name = "${local.project}-public"
  }
} 
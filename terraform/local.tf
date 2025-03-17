# 로컬 환경변수 지정
locals {
  project = "seungdobae-dev"
  tags = {
    "Terraform" = "true"
  }
}

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
}

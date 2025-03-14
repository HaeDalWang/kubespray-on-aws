# 요구되는 테라폼 제공자 목록
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.91.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.36.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.0-pre2"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.1.3"
    }
  }
}

# 테라폼 백엔드 설정
# 필요 시 주석을 풀고 사용 내용은 바꿔야합니다
# terraform {
#   backend "s3" {
#     region         = "ap-northeast-2"
#     bucket         = "-terraform-state"
#     key            = "/terraform.tfstate"
#     dynamodb_table = "-terraform-lock"
#     encrypt        = true
#     assume_role = {
#       role_arn = "arn:aws:iam:::role/"
#     }
#   }
# }

# AWS 제공자 설정
provider "aws" {
  default_tags {
    tags = local.tags
  }
}

# Kubernetes 제공자 설정
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

# Helm 제공자 설정
provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
  debug = true
}

# Kubectl 제공자 설정
provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
  load_config_file       = false
}

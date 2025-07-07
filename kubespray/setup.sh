#!/bin/bash

# kubespray 관리를 위한 인스턴스 환경 구성 스크립트

set -e

echo "🚀 kubespray 클러스터 매니저 환경 구성을 시작합니다..."

# 시스템 업데이트
echo "📦 시스템 업데이트 중..."
sudo apt update
sudo apt upgrade -y

# 필수 패키지 설치
echo "📦 필수 패키지 설치 중..."
sudo apt install -y \
    docker.io \
    python3-pip \
    git \
    curl \
    vim \
    jq \
    unzip \
    software-properties-common

# Docker 서비스 활성화
echo "🐳 Docker 서비스 구성 중..."
sudo systemctl enable docker
sudo systemctl start docker

# Docker 권한 추가
sudo usermod -aG docker ubuntu
sudo usermod -aG docker $USER

# AWS CLI 설치
echo "☁️ AWS CLI 설치 중..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws

# kubectl 설치
echo "⚙️ kubectl 설치 중..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# helm 설치
echo "⚙️ Helm 설치 중..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# kubespray 이미지 다운로드
echo "🐳 kubespray Docker 이미지 다운로드 중..."
docker pull quay.io/kubespray/kubespray:v2.28.0

echo "✅ kubespray 환경 구성이 완료되었습니다!"
echo ""
echo "다음 단계:"
echo "1. 인스턴스 정보로 inventory/hosts.yaml 파일 업데이트"
echo "2. cluster.yaml 파일 검토 및 수정"
echo "3. SSH 공개키를 모든 노드에 복사"
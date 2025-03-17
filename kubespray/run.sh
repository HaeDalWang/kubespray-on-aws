#!/bin/bash

# Docker 설치 여부 확인
if ! command -v docker &> /dev/null; then
    echo "Docker가 설치되어 있지 않습니다. 설치를 진행합니다..."

    # 패키지 업데이트 및 필요한 패키지 설치
    sudo apt update
    sudo apt install -y ca-certificates curl gnupg

    # Docker 공식 GPG 키 추가
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Docker 저장소 추가
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Docker 설치
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # ubuntu user의 Docker 권한 추가 
    sudo usermod -aG docker ubuntu 

    # Docker 서비스 시작 및 활성화
    sudo systemctl enable --now docker
    sudo systemctl restart docker

    echo "Docker 설치가 완료되었습니다."
else
    echo "Docker가 이미 설치되어 있습니다."
    echo "원하는 Docker 명령어를 직접 실행하세요."
fi


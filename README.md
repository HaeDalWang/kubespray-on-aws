# Kubespray on AWS

이 프로젝트는 AWS 환경에서 Kubespray를 사용하여 Kubernetes 클러스터를 자동으로 설치하고 관리하는 도구입니다.

## 🏗️ 아키텍처

- **Master 노드**: 3대 (High Availability)
- **Worker 노드**: 2대
- **Ingress 노드**: 2대 (Public Subnet)
- **Kubespray 관리 노드**: 1대 (Public Subnet)

## 📁 파일 구조

```
kubespray/
├── setup.sh                    # 초기 환경 설정 스크립트
├── run.sh                      # kubespray 실행 스크립트
├── ssh-setup.sh                # SSH 키 배포 스크립트
├── update-inventory.sh         # inventory 자동 업데이트 스크립트
├── inventory/
│   └── hosts.yaml              # Ansible inventory 파일
├── group_vars/
│   ├── all/
│   │   └── cluster.yaml        # 클러스터 기본 설정
│   └── k8s_cluster/
│       └── addons.yaml         # 애드온 설정
└── README.md                   # 이 파일
```

## 🚀 설치 단계

### 1. 인프라 구성 (Terraform)

```bash
# terraform 디렉토리에서 실행
cd ../terraform
terraform init
terraform plan
terraform apply
```

### 2. Kubespray 관리 노드 설정

kubespray 인스턴스에 SSH 접속한 후:

```bash
# 환경 설정 스크립트 실행
chmod +x setup.sh
./setup.sh

# 로그아웃 후 다시 로그인 (Docker 권한 적용)
exit
# 다시 SSH 접속
```

### 3. Inventory 파일 업데이트

```bash
# Terraform output으로 inventory 파일 자동 생성
chmod +x update-inventory.sh
./update-inventory.sh

# inventory 파일 확인
cat ~/kubespray-work/inventory/hosts.yaml
```

### 4. SSH 키 배포

```bash
# 모든 클러스터 노드에 SSH 키 배포
chmod +x ssh-setup.sh
./ssh-setup.sh

# SSH 연결 테스트
./ssh-setup.sh test
```

### 5. 클러스터 설치

```bash
# 클러스터 설치 실행
chmod +x run.sh
./run.sh install
```

## 🔧 사용법

### 클러스터 관리 명령어

```bash
# 클러스터 설치
./run.sh install

# 노드 추가 (스케일링)
./run.sh scale

# 클러스터 업그레이드
./run.sh upgrade

# 클러스터 초기화 (주의: 모든 데이터 삭제)
./run.sh reset

# kubespray 컨테이너 쉘 접속
./run.sh shell

# 도움말 출력
./run.sh --help
```

### SSH 키 관리

```bash
# SSH 키 배포
./ssh-setup.sh deploy

# SSH 연결 테스트
./ssh-setup.sh test

# 배포 + 테스트 (기본값)
./ssh-setup.sh
```

### Inventory 관리

```bash
# inventory 파일 업데이트
./update-inventory.sh

# 특정 terraform 디렉토리 지정
./update-inventory.sh -t /path/to/terraform

# 도움말 출력
./update-inventory.sh --help
```

## 📋 설치 후 확인

### 1. kubectl 설정

마스터 노드 중 하나에 SSH 접속:

```bash
# kubeconfig 파일 복사
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# 클러스터 상태 확인
kubectl get nodes
kubectl get pods --all-namespaces
```

### 2. kubeconfig 다운로드

로컬 환경에서 kubectl 사용을 위해:

```bash
# 마스터 노드에서 kubeconfig 다운로드
scp ubuntu@<MASTER_IP>:~/.kube/config ~/.kube/config

# 클러스터 접근 테스트
kubectl get nodes
```

### 3. 인그레스 컨트롤러 확인

```bash
# 인그레스 컨트롤러 상태 확인
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# 인그레스 노드 확인
kubectl get nodes --selector=node-role.kubernetes.io/ingress=true
```

## 🛠️ 트러블슈팅

### 일반적인 문제

1. **SSH 키 배포 실패**
   ```bash
   # SSH 키 재생성
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
   
   # 키 배포 재시도
   ./ssh-setup.sh deploy
   ```

2. **inventory 파일 오류**
   ```bash
   # inventory 파일 재생성
   ./update-inventory.sh
   
   # 수동으로 IP 주소 확인
   cd ../terraform
   terraform output
   ```

3. **클러스터 설치 실패**
   ```bash
   # 로그 확인
   ./run.sh shell
   
   # 수동으로 playbook 실행
   ansible-playbook -i inventory/hosts.yaml cluster.yml -b -v
   ```

### 로그 확인

```bash
# kubespray 컨테이너 로그
docker logs kubespray

# 시스템 로그
sudo journalctl -u kubelet
sudo journalctl -u containerd
```

## 📚 추가 정보

### 클러스터 구성 정보

- **Kubernetes 버전**: v1.29.8
- **컨테이너 런타임**: containerd
- **네트워크 플러그인**: Calico
- **인그레스 컨트롤러**: NGINX Ingress Controller
- **DNS**: CoreDNS with NodeLocal DNS

### 네트워크 구성

- **서비스 서브넷**: 10.233.0.0/18
- **포드 서브넷**: 10.233.64.0/18
- **VPC CIDR**: 10.0.0.0/16 (terraform 설정에 따라 변경)

### 보안 그룹

- **공통 보안 그룹**: 모든 Kubernetes 포트 + SSH (VPC 내부)
- **Public 보안 그룹**: HTTP/HTTPS + SSH (인터넷)

## 🔐 보안 고려사항

1. **SSH 키 관리**
   - 정기적으로 SSH 키 로테이션
   - 불필요한 키 제거

2. **보안 그룹 최적화**
   - SSH 접근을 특정 IP로 제한
   - 불필요한 포트 닫기

3. **클러스터 보안**
   - RBAC 활성화
   - 네트워크 정책 적용
   - 정기적인 보안 업데이트

## 🤝 기여하기

이슈나 개선사항이 있다면 GitHub Issues를 통해 제안해주세요.

## 📄 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다. 
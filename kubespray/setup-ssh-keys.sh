#!/bin/bash

# kubespray 전용 SSH 키 생성 및 배포 스크립트 (ssh-copy-id 사용)

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 설정 변수
KUBESPRAY_KEY_NAME="kubespray"
KUBESPRAY_PRIVATE_KEY="$HOME/.ssh/${KUBESPRAY_KEY_NAME}"
KUBESPRAY_PUBLIC_KEY="$HOME/.ssh/${KUBESPRAY_KEY_NAME}.pub"
EXISTING_PRIVATE_KEY="$HOME/.ssh/seungdobae.pem"
INVENTORY_FILE="./inventory/inventory.yaml"
SSH_USER="ubuntu"

# 호스트 목록 (고정 IP들)
HOSTS=(
    "172.22.10.10"  # master-1
    "172.22.10.11"  # master-2
    "172.22.10.12"  # master-3
    "172.22.10.20"  # worker-1
    "172.22.10.21"  # worker-2
    "172.22.0.11"   # ingress-1
    "172.22.0.12"   # ingress-2
)

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# SSH 키 생성 함수
generate_ssh_key() {
    log_info "🔑 kubespray 전용 SSH 키 생성 중..."
    
    # 기존 키가 있으면 백업
    if [ -f "$KUBESPRAY_PRIVATE_KEY" ]; then
        log_warning "기존 kubespray 키가 발견되었습니다. 백업 중..."
        cp "$KUBESPRAY_PRIVATE_KEY" "$KUBESPRAY_PRIVATE_KEY.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$KUBESPRAY_PUBLIC_KEY" "$KUBESPRAY_PUBLIC_KEY.bak.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # 새 키 생성
    ssh-keygen -t rsa -b 4096 -f "$KUBESPRAY_PRIVATE_KEY" -N "" -C "kubespray@$(hostname)"
    
    # 권한 설정
    chmod 600 "$KUBESPRAY_PRIVATE_KEY"
    chmod 644 "$KUBESPRAY_PUBLIC_KEY"
    
    log_success "SSH 키 생성 완료"
    log_info "  - Private key: $KUBESPRAY_PRIVATE_KEY"
    log_info "  - Public key: $KUBESPRAY_PUBLIC_KEY"
}

# ssh-copy-id로 키 복사 함수
copy_key_to_host() {
    local host=$1
    
    log_info "📋 $host에 키 복사 중..."
    
    # ssh-copy-id 사용하여 키 복사
    if ssh-copy-id -i "$KUBESPRAY_PUBLIC_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$SSH_USER@$host" 2>/dev/null; then
        log_success "$host 키 복사 완료"
        return 0
    else
        log_error "$host 키 복사 실패"
        return 1
    fi
}

# 새 키로 연결 테스트 함수
test_new_key_connection() {
    local host=$1
    
    log_info "🔧 $host 새 키 연결 테스트 중..."
    
    # 새 키로 SSH 연결 테스트
    if ssh -i "$KUBESPRAY_PRIVATE_KEY" \
           -o ConnectTimeout=10 \
           -o StrictHostKeyChecking=no \
           -o UserKnownHostsFile=/dev/null \
           -o LogLevel=ERROR \
           "$SSH_USER@$host" "echo 'Connection successful'" > /dev/null 2>&1; then
        log_success "$host 연결 성공"
        return 0
    else
        log_error "$host 연결 실패"
        return 1
    fi
}

# 메인 함수
main() {
    log_info "🚀 kubespray SSH 키 설정을 시작합니다..."
    echo
    
    # 기존 키 존재 확인
    if [ ! -f "$EXISTING_PRIVATE_KEY" ]; then
        log_error "기존 private key를 찾을 수 없습니다: $EXISTING_PRIVATE_KEY"
        log_error "seungdobae.pem 키가 ~/.ssh/ 디렉토리에 있는지 확인하세요."
        exit 1
    fi
    
    # 기존 키 권한 확인
    chmod 600 "$EXISTING_PRIVATE_KEY"
    
    # SSH 키 생성
    generate_ssh_key
    echo
    
    # 호스트 목록 출력
    log_info "📋 처리할 호스트 목록:"
    for host in "${HOSTS[@]}"; do
        echo "  - $host"
    done
    echo
    
    # SSH Agent에 기존 키 추가 (ssh-copy-id가 사용할 수 있도록)
    log_info "🔐 SSH Agent에 기존 키 추가 중..."
    eval "$(ssh-agent -s)" > /dev/null 2>&1
    ssh-add "$EXISTING_PRIVATE_KEY" > /dev/null 2>&1
    ssh-add "$KUBESPRAY_PRIVATE_KEY" > /dev/null 2>&1

    # 각 호스트에 키 복사
    success_count=0
    failed_hosts=()
    
    for host in "${HOSTS[@]}"; do
        log_info "🔄 $host 처리 중..."
        
        if copy_key_to_host "$host"; then
            if test_new_key_connection "$host"; then
                success_count=$((success_count + 1))
                log_success "$host 설정 완료 ✅"
            else
                failed_hosts+=("$host")
            fi
        else
            failed_hosts+=("$host")
        fi
        echo
    done
    
    # SSH Agent 종료
    ssh-agent -k > /dev/null 2>&1
    
    # 최종 결과 출력
    echo "════════════════════════════════════════════════════════════════════════════════"
    log_info "📊 SSH 키 설정 완료!"
    echo
    
    # 최종 검증
    log_info "🔍 최종 검증 중..."
    for host in "${HOSTS[@]}"; do
        if test_new_key_connection "$host" > /dev/null 2>&1; then
            echo "  ✅ $host"
        else
            echo "  ❌ $host"
        fi
    done
    
    echo
    if [ ${#failed_hosts[@]} -eq 0 ]; then
        log_success "🎉 모든 호스트에 SSH 키 설정이 성공적으로 완료되었습니다!"
        log_info "성공: $success_count/${#HOSTS[@]} 호스트"
        echo
        log_info "이제 다음 명령어로 kubespray를 실행할 수 있습니다:"
        log_info "  1. ./docker-run.sh"
        log_info "  2. docker exec -it kubespray bash"
        log_info "  3. cd inventory && ./playbook-run.sh"
    else
        log_warning "⚠️  일부 호스트에서 SSH 키 설정이 실패했습니다."
        log_warning "성공: $success_count/${#HOSTS[@]} 호스트"
        log_warning "실패한 호스트: ${failed_hosts[*]}"
    fi
    
    echo "════════════════════════════════════════════════════════════════════════════════"
}

# 스크립트 실행
main "$@" 
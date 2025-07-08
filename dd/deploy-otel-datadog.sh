#!/bin/bash

# OpenTelemetry + Datadog 통합 배포 스크립트

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 설정 변수
NAMESPACE="datadog"
DD_API_KEY="${DD_API_KEY:-}"

# 사용법 출력
usage() {
    echo "사용법: $0 [명령어]"
    echo ""
    echo "명령어:"
    echo "  deploy    - 전체 OpenTelemetry + Datadog 스택 배포"
    echo "  update    - 기존 설정 업데이트"
    echo "  status    - 배포 상태 확인"
    echo "  cleanup   - 모든 리소스 삭제"
    echo "  logs      - 로그 확인"
    echo "  test      - 테스트 실행"
    echo ""
    echo "환경 변수:"
    echo "  DD_API_KEY - Datadog API 키 (필수)"
    echo ""
    echo "예제:"
    echo "  export DD_API_KEY=your_api_key_here"
    echo "  $0 deploy"
}

# API 키 확인
check_api_key() {
    if [ -z "$DD_API_KEY" ]; then
        log_error "DD_API_KEY 환경 변수가 설정되지 않았습니다."
        log_error "다음과 같이 설정하세요: export DD_API_KEY=your_api_key_here"
        exit 1
    fi
}

# 네임스페이스 생성
create_namespace() {
    log_info "네임스페이스 '$NAMESPACE' 생성 중..."
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    log_success "네임스페이스 생성 완료"
}

# Datadog Secret 생성
create_datadog_secret() {
    log_info "Datadog API 키 Secret 생성 중..."
    kubectl create secret generic datadog-secret \
        --from-literal=api-key="$DD_API_KEY" \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    log_success "Datadog Secret 생성 완료"
}

# Datadog Operator 설치
install_datadog_operator() {
    log_info "Datadog Operator 설치 중..."
    helm repo add datadog https://helm.datadoghq.com --force-update
    helm repo update
    
    helm upgrade --install datadog-operator datadog/datadog-operator \
        --namespace=$NAMESPACE \
        --create-namespace \
        --wait
    
    # Operator가 준비될 때까지 대기
    kubectl wait --for=condition=Ready pod -l name=datadog-operator --namespace=$NAMESPACE --timeout=300s
    log_success "Datadog Operator 설치 완료"
}

# OpenTelemetry Collector 배포
deploy_otel_collector() {
    log_info "OpenTelemetry Collector 배포 중..."
    
    # ConfigMap 적용
    kubectl apply -f otel-collector-config.yaml
    
    # RBAC 적용
    kubectl apply -f otel-collector-rbac.yaml
    
    # DaemonSet 적용
    kubectl apply -f otel-collector-daemonset.yaml
    
    # Pods가 준비될 때까지 대기
    log_info "OpenTelemetry Collector Pods가 준비될 때까지 대기 중..."
    kubectl rollout status daemonset/otel-collector --namespace=$NAMESPACE --timeout=300s
    
    log_success "OpenTelemetry Collector 배포 완료"
}

# Datadog Agent 배포
deploy_datadog_agent() {
    log_info "Datadog Agent 배포 중..."
    
    # 업데이트된 Datadog Agent 적용
    kubectl apply -f datadog-agent-updated.yaml
    
    # Agent가 준비될 때까지 대기
    log_info "Datadog Agent가 준비될 때까지 대기 중..."
    kubectl wait --for=condition=Ready datadogagent/datadog --namespace=$NAMESPACE --timeout=600s
    
    log_success "Datadog Agent 배포 완료"
}

# 테스트 애플리케이션 배포
deploy_test_app() {
    log_info "테스트 애플리케이션 배포 중..."
    
    kubectl apply -f example-app.yaml
    
    # 애플리케이션이 준비될 때까지 대기
    kubectl rollout status deployment/otel-demo-app --namespace=$NAMESPACE --timeout=300s
    
    log_success "테스트 애플리케이션 배포 완료"
}

# 전체 배포
deploy_all() {
    log_info "🚀 OpenTelemetry + Datadog 통합 스택 배포 시작"
    
    check_api_key
    create_namespace
    create_datadog_secret
    install_datadog_operator
    deploy_otel_collector
    deploy_datadog_agent
    deploy_test_app
    
    log_success "🎉 모든 구성 요소가 성공적으로 배포되었습니다!"
    
    echo ""
    log_info "📊 배포 상태 확인:"
    show_status
    
    echo ""
    log_info "🔗 유용한 명령어:"
    echo "  상태 확인: $0 status"
    echo "  로그 확인: $0 logs"
    echo "  테스트 실행: $0 test"
}

# 상태 확인
show_status() {
    log_info "📊 배포 상태 확인 중..."
    
    echo ""
    echo "=== 네임스페이스 리소스 ==="
    kubectl get all -n $NAMESPACE
    
    echo ""
    echo "=== OpenTelemetry Collector 상태 ==="
    kubectl get pods -n $NAMESPACE -l app=otel-collector
    
    echo ""
    echo "=== Datadog Agent 상태 ==="
    kubectl get datadogagent -n $NAMESPACE
    kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=datadog
    
    echo ""
    echo "=== 테스트 애플리케이션 상태 ==="
    kubectl get pods -n $NAMESPACE -l app=otel-demo-app
    
    echo ""
    echo "=== 서비스 엔드포인트 ==="
    kubectl get svc -n $NAMESPACE
}

# 로그 확인
check_logs() {
    log_info "📋 주요 구성 요소 로그 확인"
    
    echo ""
    echo "=== OpenTelemetry Collector 로그 ==="
    kubectl logs -n $NAMESPACE -l app=otel-collector --tail=20
    
    echo ""
    echo "=== Datadog Agent 로그 ==="
    kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=datadog --tail=20
    
    echo ""
    echo "=== 테스트 애플리케이션 로그 ==="
    kubectl logs -n $NAMESPACE -l app=otel-demo-app --tail=10
}

# 테스트 실행
run_tests() {
    log_info "🧪 연결 및 기능 테스트 실행"
    
    # OpenTelemetry Collector 헬스 체크
    echo ""
    log_info "OpenTelemetry Collector 헬스 체크..."
    kubectl get pods -n $NAMESPACE -l app=otel-collector -o name | while read pod; do
        echo "Testing $pod..."
        kubectl exec -n $NAMESPACE $pod -- curl -f http://localhost:13133/ || log_warning "$pod 헬스 체크 실패"
    done
    
    # 테스트 애플리케이션 접근
    echo ""
    log_info "테스트 애플리케이션 접근 확인..."
    kubectl run test-pod --image=curlimages/curl --rm -i --restart=Never --namespace=$NAMESPACE -- \
        curl -f http://otel-demo-app/api/health || log_warning "테스트 애플리케이션 접근 실패"
    
    echo ""
    log_success "테스트 완료! Datadog 대시보드에서 메트릭, 로그, 트레이스를 확인하세요."
    echo "대시보드 URL: https://ap1.datadoghq.com/"
}

# 설정 업데이트
update_config() {
    log_info "🔄 설정 업데이트 중..."
    
    # ConfigMap 업데이트
    kubectl apply -f otel-collector-config.yaml
    
    # Datadog Agent 업데이트
    kubectl apply -f datadog-agent-updated.yaml
    
    # OpenTelemetry Collector 재시작
    kubectl rollout restart daemonset/otel-collector -n $NAMESPACE
    
    log_success "설정 업데이트 완료"
}

# 정리
cleanup() {
    log_warning "⚠️  모든 리소스를 삭제하시겠습니까? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        log_info "🧹 리소스 정리 중..."
        
        # 네임스페이스 전체 삭제
        kubectl delete namespace $NAMESPACE --ignore-not-found=true
        
        # Datadog Operator 삭제
        helm uninstall datadog-operator --namespace=$NAMESPACE || true
        
        log_success "정리 완료"
    else
        log_info "정리가 취소되었습니다."
    fi
}

# 메인 함수
main() {
    case "${1:-}" in
        "deploy")
            deploy_all
            ;;
        "update")
            update_config
            ;;
        "status")
            show_status
            ;;
        "logs")
            check_logs
            ;;
        "test")
            run_tests
            ;;
        "cleanup")
            cleanup
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

# 스크립트 실행
main "$@" 
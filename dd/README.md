# OpenTelemetry + Datadog 통합 가이드

이 가이드는 Kubernetes 환경에서 OpenTelemetry Collector를 사용하여 **로그, 메트릭, 트레이스**를 모두 Datadog으로 전송하는 완전한 통합 솔루션을 제공합니다.

## 🏗️ 아키텍처

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   애플리케이션    │────│ OpenTelemetry   │────│    Datadog      │
│                 │    │   Collector     │    │                 │
│ • 로그 생성      │    │                 │    │ • 대시보드       │
│ • 메트릭 발생    │────│ • 수집          │────│ • 알림          │
│ • 트레이스 전송  │    │ • 변환          │    │ • 분석          │
└─────────────────┘    │ • 전송          │    └─────────────────┘
                       └─────────────────┘
                              │
                              │
                       ┌─────────────────┐
                       │  Datadog Agent  │
                       │                 │
                       │ • 인프라 메트릭  │
                       │ • 프로세스 모니터 │
                       │ • 보안 모니터링  │
                       └─────────────────┘
```

## 📦 구성 요소

### 1. OpenTelemetry Collector
- **역할**: 모든 텔레메트리 데이터의 중앙 수집점
- **배포**: DaemonSet (각 노드당 1개)
- **기능**:
  - OTLP 프로토콜로 트레이스/메트릭/로그 수신
  - Kubernetes 메타데이터 자동 추가
  - Prometheus 메트릭 스크래핑
  - 컨테이너 로그 파일 수집
  - Datadog으로 데이터 전송

### 2. Datadog Agent
- **역할**: 인프라 모니터링 및 보안
- **배포**: DaemonSet + ClusterAgent
- **기능**:
  - 호스트 메트릭 수집
  - 프로세스 모니터링
  - 네트워크 성능 모니터링
  - 보안 모니터링 (CSPM, CWS)
  - OpenTelemetry 데이터 수신

### 3. 테스트 애플리케이션
- **역할**: 통합 테스트 및 데모
- **기능**:
  - 구조화된 로그 생성
  - HTTP 메트릭 노출
  - 트레이스 헤더 처리
  - 다양한 응답 시나리오

## 🚀 빠른 시작

### 1. 사전 요구사항

```bash
# Kubernetes 클러스터 (v1.19+)
kubectl version

# Helm (v3.0+)
helm version

# Datadog API 키
export DD_API_KEY="your_datadog_api_key_here"
```

### 2. 전체 배포

```bash
# 1. API 키 설정
export DD_API_KEY="your_datadog_api_key_here"

# 2. 전체 스택 배포
./deploy-otel-datadog.sh deploy

# 3. 배포 상태 확인
./deploy-otel-datadog.sh status

# 4. 테스트 실행
./deploy-otel-datadog.sh test
```

### 3. 상태 확인

```bash
# 전체 상태 확인
kubectl get all -n datadog

# OpenTelemetry Collector 상태
kubectl get pods -n datadog -l app=otel-collector

# Datadog Agent 상태
kubectl get datadogagent -n datadog
```

## 📋 상세 설정

### OpenTelemetry Collector 설정

```yaml
# otel-collector-config.yaml에서 주요 설정
receivers:
  otlp:          # 애플리케이션에서 직접 전송
  filelog:       # 컨테이너 로그 수집
  k8s_cluster:   # Kubernetes 메트릭
  prometheus:    # Prometheus 메트릭 스크래핑

processors:
  k8sattributes: # Kubernetes 메타데이터 추가
  batch:         # 배치 처리로 성능 최적화
  resourcedetection: # 리소스 자동 감지

exporters:
  datadog:       # Datadog으로 모든 데이터 전송
```

### Datadog Agent 설정

```yaml
# datadog-agent-updated.yaml에서 주요 설정
features:
  apm:
    otlp:        # OpenTelemetry 수신 활성화
  logCollection: # 로그 수집
  npm:           # 네트워크 모니터링
  cspm:          # 보안 모니터링
```

## 🔧 사용법

### 애플리케이션에서 OpenTelemetry 사용

#### 환경 변수 설정
```yaml
env:
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: "http://otel-collector:4318"
- name: OTEL_SERVICE_NAME
  value: "my-app"
- name: OTEL_RESOURCE_ATTRIBUTES
  value: "service.name=my-app,service.version=1.0.0"
```

#### Python 예제
```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# 트레이서 설정
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

# OTLP Exporter 설정
otlp_exporter = OTLPSpanExporter(
    endpoint="http://otel-collector:4318/v1/traces"
)
span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

# 트레이스 생성
with tracer.start_as_current_span("my-operation"):
    # 비즈니스 로직
    pass
```

#### Node.js 예제
```javascript
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-otlp-http');

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: 'http://otel-collector:4318/v1/traces',
  }),
  serviceName: 'my-node-app',
});

sdk.start();
```

### 로그 구조화

```json
{
  "timestamp": "2024-01-01T12:00:00Z",
  "level": "INFO",
  "service": "my-app",
  "trace_id": "1234567890abcdef",
  "span_id": "abcdef1234567890",
  "message": "User action completed",
  "user_id": "12345",
  "action": "purchase"
}
```

## 📊 Datadog에서 확인할 수 있는 데이터

### 1. 트레이스 (APM)
- 서비스 맵
- 트레이스 검색 및 분석
- 성능 메트릭
- 에러 추적

### 2. 메트릭
- 애플리케이션 메트릭
- Kubernetes 메트릭
- 인프라 메트릭
- 사용자 정의 메트릭

### 3. 로그
- 구조화된 로그
- 트레이스 연결
- 로그 패턴 분석
- 실시간 검색

## 🛠️ 관리 명령어

```bash
# 상태 확인
./deploy-otel-datadog.sh status

# 로그 확인
./deploy-otel-datadog.sh logs

# 설정 업데이트
./deploy-otel-datadog.sh update

# 테스트 실행
./deploy-otel-datadog.sh test

# 전체 정리
./deploy-otel-datadog.sh cleanup
```

## 🔍 트러블슈팅

### 일반적인 문제들

#### 1. OpenTelemetry Collector가 시작되지 않음
```bash
# 로그 확인
kubectl logs -n datadog -l app=otel-collector

# 설정 확인
kubectl get configmap otel-collector-config -n datadog -o yaml
```

#### 2. Datadog에 데이터가 나타나지 않음
```bash
# API 키 확인
kubectl get secret datadog-secret -n datadog -o yaml

# Collector 상태 확인
kubectl exec -n datadog $(kubectl get pods -n datadog -l app=otel-collector -o name | head -1) -- curl http://localhost:13133/
```

#### 3. 애플리케이션에서 트레이스 전송 실패
```bash
# 서비스 엔드포인트 확인
kubectl get svc otel-collector -n datadog

# 네트워크 연결 테스트
kubectl run test --image=curlimages/curl --rm -i --restart=Never -- curl -v http://otel-collector.datadog:4318/v1/traces
```

### 성능 최적화

#### 1. 리소스 할당 조정
```yaml
resources:
  requests:
    cpu: 200m
    memory: 512Mi
  limits:
    cpu: 500m
    memory: 1Gi
```

#### 2. 배치 크기 조정
```yaml
processors:
  batch:
    send_batch_size: 2048
    timeout: 5s
```

## 📈 모니터링 및 알림

### Datadog 대시보드 설정
1. **APM 서비스 맵**: 마이크로서비스 간 의존성 시각화
2. **인프라 대시보드**: Kubernetes 클러스터 상태
3. **로그 탐색**: 실시간 로그 검색 및 분석
4. **사용자 정의 대시보드**: 비즈니스 메트릭

### 권장 알림
- 서비스 응답 시간 증가
- 에러율 상승
- 리소스 사용량 임계치 초과
- 보안 이벤트 발생

## 🔒 보안 고려사항

1. **API 키 관리**: Kubernetes Secret 사용
2. **네트워크 정책**: 필요한 통신만 허용
3. **RBAC**: 최소 권한 원칙 적용
4. **데이터 암호화**: 전송 중 암호화 활성화

## 📝 라이센스

이 프로젝트는 MIT 라이센스 하에 있습니다.

## 🤝 기여하기

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 지원

문제가 발생하거나 질문이 있으시면:
1. GitHub Issues에 등록
2. Datadog 공식 문서 참조
3. OpenTelemetry 커뮤니티 참여

---

**Happy Monitoring! 🎉** 
# Kubepray-on-aws

## 개요
AWS에서 EC2를 Terraform을 통해 생성하고 kubespray를 이용하여 쿠버네티스를 구축합니다
최신일 기준: 2025년 7월 7일

## 요구 사항
- 미리 만들어진 ec2 keypair

## 사용된 Terraform 제공자
이 프로젝트에서 사용된 Terraform 제공자 목록과 버전은 다음과 같습니다.

| 제공자 | 소스 | 버전 |
|--------|------|------|
| aws | hashicorp/aws | 6.2.0 |

## 사용된 Terraform 모듈
| 모듈 | 버전 |
|--------|------|
| terraform-aws-modules/vpc/aws | 6.0.1 |

## 적용 방법
아래 명령어를 실행합니다

1. Terraform 초기화
   ```sh
   terraform init
   ```
2. 실행 계획 확인
   ```sh
   terraform plan
   ```
3. 인프라 적용
   ```sh
   terraform apply
   ```

# Kubepray-on-aws

## 개요
AWS에서 EC2를 Terraform을 통해 생성하고 kubespray를 이용하여 쿠버네티스를 구축합니다

## 요구 사항
- 미리 만들어진 ec2 keypair

## 사용된 Terraform 제공자
이 프로젝트에서 사용된 Terraform 제공자 목록과 버전은 다음과 같습니다.

| 제공자 | 소스 | 버전 |
|--------|------|------|
| aws | hashicorp/aws | 5.91.0 |
| kubernetes | hashicorp/kubernetes | 2.36.0 |
| helm | hashicorp/helm | 3.0.0-pre2 |
| kubectl | alekc/kubectl | 2.1.3 |

## 사용된 Terraform 모듈
| 모듈 | 버전 |
|--------|------|
| terraform-aws-modules/vpc/aws | 5.19.0 |

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

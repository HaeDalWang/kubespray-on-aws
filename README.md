# Kubepray-on-aws

## 개요
AWS에서 EC2를 Terraform을 통해 생성하고 kubespray를 이용하여 쿠버네티스를 구축합니다

## 요구 사항
- Terraform v1.11.2 이상 설치
- 미리 만들어진 EC2 Keypair

## 사용방법
1. terraform 디텍토리로 이동하여 환경을 배포합니다
2. management 인스턴스에 접속하여 해당 레포지토리를 가져옵니다
3. kubespray 디텍토리로 이동하여 환경에 맞춰 인벤토리를 수정하고 배포합니다

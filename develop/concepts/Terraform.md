---
created: 2026-02-24
updated: 2026-02-24
tags: [concept, devops, cloud, infrastructure]
status: done
---

# Terraform

> HashiCorp이 개발한 오픈소스 [[IaC]] 도구로, HCL 문법을 사용하여 멀티 클라우드 인프라를 선언적으로 관리합니다.

---

## 1. 정의

Terraform은 인프라를 코드로 정의하고 프로비저닝하는 도구입니다. HCL(HashiCorp Configuration Language)이라는 전용 언어로 원하는 인프라 상태를 선언하면, Terraform이 현재 상태와 비교하여 필요한 변경을 자동으로 수행합니다.

가장 큰 특징은 **멀티 클라우드 지원**입니다. AWS, GCP, Azure는 물론 GitHub, Datadog 등 수천 개의 서비스를 하나의 도구로 관리할 수 있습니다.

---

## 2. 등장 배경 및 필요성

- **클라우드 종속 탈피**: [[CloudFormation]]은 AWS 전용이므로, 여러 클라우드를 사용하는 환경에서는 클라우드마다 다른 도구를 학습해야 했습니다. Terraform은 하나의 문법으로 모든 클라우드를 관리할 수 있도록 설계되었습니다.
- **통합 워크플로우**: 클라우드 인프라뿐 아니라 DNS, 모니터링, CI/CD 등 다양한 서비스를 하나의 코드베이스에서 관리할 필요가 있었습니다.
- **선언형 관리의 표준화**: 인프라 관리를 위한 범용적이고 일관된 선언형 도구가 필요했습니다.

---

## 3. 작동 원리 / 핵심 개념

### 3.1 HCL 문법

HCL은 Terraform 전용 설정 언어입니다. JSON보다 읽기 쉽고, 프로그래밍 언어보다 단순한 중간 지점을 목표로 합니다.

```hcl
# VPC 생성
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# 서브넷 생성 - VPC를 참조
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}
```

리소스 간 참조(`aws_vpc.main.id`)를 통해 Terraform이 자동으로 의존 관계를 파악하고 올바른 순서로 생성합니다.

### 3.2 Provider

Provider는 Terraform이 특정 서비스와 통신하기 위한 플러그인입니다. AWS, GCP, Azure 등 클라우드뿐 아니라 GitHub, Kubernetes, Datadog 등 다양한 서비스용 Provider가 존재합니다.

```hcl
# AWS Provider 설정
provider "aws" {
  region = "ap-northeast-2"
}
```

[Terraform Registry](https://registry.terraform.io/)에 4,000개 이상의 Provider가 등록되어 있습니다.

### 3.3 State(상태)

Terraform은 관리하는 인프라의 현재 상태를 **상태 파일**(`terraform.tfstate`)에 저장합니다. 이 파일이 Terraform 작동의 핵심입니다.

```
코드(원하는 상태) ←→ 상태 파일(알고 있는 상태) ←→ 실제 인프라(현재 상태)
```

- `terraform plan`: 코드와 상태 파일을 비교하여 변경 사항을 미리 보여줌
- `terraform apply`: 계획된 변경 사항을 실제로 적용

팀 작업 시에는 상태 파일을 S3 + DynamoDB 등 원격 백엔드에 저장하여 공유하고 잠금을 관리합니다.

### 3.4 Module

반복되는 인프라 패턴을 재사용 가능한 단위로 묶은 것입니다. 함수와 유사한 개념으로, 입력 변수를 받아 리소스를 생성합니다.

```hcl
# 모듈 사용
module "vpc" {
  source = "./modules/vpc"

  cidr_block   = "10.0.0.0/16"
  environment  = "production"
}
```

### 3.5 실행 흐름

```
terraform init → terraform plan → terraform apply
  (초기화)         (변경 미리보기)     (변경 적용)
```

1. `init`: Provider 플러그인 다운로드, 백엔드 초기화
2. `plan`: 코드와 현재 상태를 비교하여 변경 계획 출력
3. `apply`: 변경 계획을 실제로 실행 (확인 후 적용)

---

## 4. 장점 및 이점

- **멀티 클라우드**: AWS, GCP, Azure 등 여러 클라우드를 하나의 도구와 문법으로 관리할 수 있습니다.
- **Plan 기능**: 실제 적용 전에 변경 사항을 미리 확인할 수 있어 실수를 방지합니다.
- **풍부한 생태계**: 수천 개의 Provider와 커뮤니티 Module이 존재합니다.
- **상태 기반 관리**: 상태 파일을 통해 인프라의 현재 상태를 정확히 추적합니다.
- **선언형 접근**: 원하는 결과만 기술하면 Terraform이 실행 순서를 자동으로 결정합니다.

---

## 5. 한계점 및 고려사항

- **상태 파일 관리**: 상태 파일이 손상되거나 동기화되지 않으면 심각한 문제가 발생합니다. 원격 백엔드 설정과 잠금 관리가 필수입니다.
- **HCL 학습**: 범용 프로그래밍 언어가 아니므로 조건문, 반복문 등의 표현이 제한적이고 직관적이지 않습니다.
- **느린 대규모 Plan**: 관리하는 리소스가 수백 개 이상이면 plan 실행 시간이 길어질 수 있습니다.
- **Provider 의존성**: Provider 버전 업데이트에 따라 코드가 깨질 수 있어, 버전 고정과 주기적 업데이트 관리가 필요합니다.
- **라이선스 변경**: 2023년 HashiCorp이 라이선스를 BSL로 변경하여, 일부 상업적 사용에 제약이 생겼습니다. 이에 따라 오픈소스 포크인 OpenTofu가 등장했습니다.

---

## 관련 문서

- [[IaC]] - 상위 개념: 인프라를 코드로 관리하는 방법론
- [[CloudFormation]] - AWS 네이티브 IaC, Terraform과 자주 비교되는 도구
- [[AWS CDK]] - 프로그래밍 언어 기반 IaC, 내부적으로 CloudFormation 사용
- [[Docker]] - Terraform으로 컨테이너 인프라를 프로비저닝하는 대표적 대상
- [[ECS]] - Terraform으로 관리하는 대표적 AWS 서비스

---

## 참고 자료

- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs) - 공식 문서
- [Terraform Registry](https://registry.terraform.io/) - Provider 및 Module 레지스트리

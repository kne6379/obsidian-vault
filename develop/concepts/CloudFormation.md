---
created: 2026-02-24
updated: 2026-02-24
tags: [concept, devops, cloud, infrastructure]
status: done
---

# CloudFormation

> AWS가 제공하는 네이티브 [[IaC]] 서비스로, JSON 또는 YAML 템플릿으로 AWS 리소스를 선언적으로 프로비저닝합니다.

---

## 1. 정의

CloudFormation은 AWS에 내장된 인프라 프로비저닝 서비스입니다. 템플릿 파일에 원하는 AWS 리소스와 설정을 선언하면, CloudFormation이 리소스 간 의존 관계를 분석하고 올바른 순서로 생성/변경/삭제합니다.

별도의 도구를 설치할 필요 없이 AWS 콘솔이나 CLI에서 바로 사용할 수 있으며, AWS 서비스와의 통합이 가장 긴밀합니다.

---

## 2. 등장 배경 및 필요성

- **AWS 인프라 자동화**: AWS 콘솔에서 수동으로 리소스를 만드는 방식의 한계를 해결하기 위해 2011년에 출시되었습니다. AWS 최초의 IaC 서비스입니다.
- **리소스 간 의존 관계 관리**: EC2를 만들기 전에 VPC와 서브넷이 있어야 하는 등, 리소스 간 생성 순서를 자동으로 처리할 필요가 있었습니다.
- **일관된 환경 복제**: 개발, 스테이징, 프로덕션 환경을 동일한 템플릿으로 생성하여 환경 간 차이를 제거하기 위한 목적이었습니다.

---

## 3. 작동 원리 / 핵심 개념

### 3.1 템플릿

CloudFormation의 핵심은 **템플릿** 파일입니다. YAML 또는 JSON 형식으로 작성하며, 다음 섹션으로 구성됩니다.

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 간단한 EC2 인스턴스 생성

Parameters:
  InstanceType:
    Type: String
    Default: t3.micro
    AllowedValues: [t3.micro, t3.small, t3.medium]

Resources:
  WebServer:
    Type: AWS::EC2::Instance
    Properties:
      InstanceType: !Ref InstanceType
      ImageId: ami-0c55b159cbfafe1f0
      Tags:
        - Key: Name
          Value: web-server

Outputs:
  InstanceId:
    Value: !Ref WebServer
```

| 섹션 | 필수 여부 | 설명 |
|------|----------|------|
| **Parameters** | 선택 | 입력 변수. 배포 시 값을 전달 |
| **Resources** | 필수 | 생성할 AWS 리소스 정의 |
| **Outputs** | 선택 | 다른 스택에서 참조할 수 있는 출력값 |
| **Mappings** | 선택 | 리전별, 환경별 설정값 매핑 |
| **Conditions** | 선택 | 조건부 리소스 생성 |

### 3.2 스택

스택은 CloudFormation의 **배포 단위**입니다. 하나의 템플릿으로 생성된 리소스들의 묶음이며, 스택을 삭제하면 포함된 리소스가 모두 함께 삭제됩니다.

```
템플릿 → 스택 생성 → AWS 리소스들
                    (VPC, EC2, RDS...)
```

### 3.3 변경 세트

인프라를 수정할 때 **변경 세트(Change Set)**를 사용합니다. 템플릿을 수정한 후 바로 적용하는 대신, 어떤 리소스가 추가/수정/삭제되는지 미리 확인할 수 있습니다.

```
템플릿 수정 → 변경 세트 생성(미리보기) → 검토 → 변경 세트 실행(적용)
```

이 기능은 [[Terraform]]의 `plan`과 유사한 역할을 합니다.

### 3.4 내장 함수

CloudFormation은 템플릿 내에서 사용할 수 있는 내장 함수를 제공합니다.

| 함수 | 용도 | 예시 |
|------|------|------|
| `!Ref` | 리소스/파라미터 참조 | `!Ref WebServer` |
| `!GetAtt` | 리소스 속성 가져오기 | `!GetAtt WebServer.PublicIp` |
| `!Sub` | 문자열 치환 | `!Sub "arn:aws:s3:::${BucketName}"` |
| `!Join` | 문자열 결합 | `!Join ["-", [prefix, suffix]]` |
| `Fn::If` | 조건부 값 | `Fn::If: [IsProd, t3.large, t3.micro]` |

### 3.5 상태 관리

CloudFormation은 AWS 내부에서 상태를 관리합니다. [[Terraform]]처럼 별도의 상태 파일을 관리할 필요가 없습니다. AWS가 각 스택의 리소스 상태를 자동으로 추적하고, 스택 이벤트를 통해 변경 이력을 제공합니다.

---

## 4. 장점 및 이점

- **AWS 완전 통합**: 별도 도구 설치 없이 AWS 콘솔/CLI에서 바로 사용 가능합니다. 새로운 AWS 서비스가 출시되면 가장 빠르게 지원됩니다.
- **무료**: CloudFormation 자체 사용에는 비용이 발생하지 않습니다. 생성된 AWS 리소스에 대해서만 과금됩니다.
- **자동 롤백**: 리소스 생성 중 오류가 발생하면 자동으로 이전 상태로 롤백합니다.
- **상태 관리 불필요**: AWS가 내부적으로 상태를 관리하므로 상태 파일 손상이나 동기화 문제가 없습니다.
- **드리프트 감지**: 콘솔에서 수동으로 변경된 리소스를 감지하는 드리프트 감지 기능을 제공합니다.

---

## 5. 한계점 및 고려사항

- **AWS 전용**: AWS 이외의 클라우드는 관리할 수 없습니다. 멀티 클라우드 환경에서는 [[Terraform]]이 필요합니다.
- **장황한 문법**: 간단한 인프라도 수백 줄의 YAML/JSON이 필요합니다. 조건문과 반복문이 직관적이지 않으며, 복잡한 로직 표현에 한계가 있습니다.
- **느린 롤백**: 배포 실패 시 자동 롤백이 수 분에서 수십 분이 소요될 수 있습니다.
- **리소스 제한**: 하나의 스택에 500개까지의 리소스만 포함할 수 있습니다. 대규모 인프라에서는 중첩 스택으로 분리해야 합니다.
- **제한적 프리뷰**: 변경 세트가 모든 종류의 변경을 정확히 예측하지 못하는 경우가 있습니다.

---

## 6. 실무 적용 가이드

### 6.1 CloudFormation vs AWS CDK

CloudFormation을 직접 사용할지, [[AWS CDK]]를 사용할지는 팀 상황에 따라 다릅니다.

| 상황 | 추천 |
|------|------|
| 인프라가 단순하고 개발 인력이 적음 | CloudFormation |
| 복잡한 조건/반복 로직이 필요 | AWS CDK |
| 기존 CloudFormation 템플릿이 많음 | CloudFormation (점진적으로 CDK 도입) |
| 개발팀이 TypeScript/Python에 익숙 | AWS CDK |

### 6.2 중첩 스택

대규모 인프라에서는 하나의 거대한 템플릿 대신 **중첩 스택(Nested Stack)**으로 분리합니다.

```
루트 스택
├── 네트워크 스택 (VPC, 서브넷, 보안 그룹)
├── 데이터베이스 스택 (RDS, ElastiCache)
└── 애플리케이션 스택 (ECS, ALB)
```

---

## 관련 문서

- [[IaC]] - 상위 개념: 인프라를 코드로 관리하는 방법론
- [[AWS CDK]] - CloudFormation을 내부적으로 사용하는 고수준 IaC 프레임워크
- [[Terraform]] - 멀티 클라우드 지원 IaC 도구, CloudFormation과 자주 비교됨
- [[ECS]] - CloudFormation으로 관리하는 대표적 AWS 서비스
- [[Docker]] - CloudFormation/ECS에서 배포하는 컨테이너 기술

---

## 참고 자료

- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/) - 공식 문서
- [AWS CloudFormation Resource Reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html) - 리소스 타입 레퍼런스

---
created: 2026-02-24
updated: 2026-02-24
tags: [concept, devops, cloud, infrastructure]
status: done
---

# AWS CDK

> 범용 프로그래밍 언어(TypeScript, Python 등)로 AWS 인프라를 정의하고, 내부적으로 [[CloudFormation]] 템플릿을 생성하는 [[IaC]] 프레임워크입니다.

---

## 1. 정의

AWS CDK(Cloud Development Kit)는 AWS가 제공하는 오픈소스 IaC 프레임워크입니다. TypeScript, Python, Java, C#, Go 등 익숙한 프로그래밍 언어로 인프라를 정의할 수 있습니다.

작성한 코드는 **합성(Synth)** 과정을 거쳐 [[CloudFormation]] 템플릿으로 변환되며, 실제 배포는 CloudFormation이 수행합니다. 즉, 프로그래밍 언어의 편의성과 CloudFormation의 안정성을 결합한 도구입니다.

---

## 2. 등장 배경 및 필요성

- **CloudFormation의 장황함**: JSON/YAML로 인프라를 정의하면 수백~수천 줄의 템플릿이 되기 쉬우며, 조건문이나 반복문 표현이 매우 제한적입니다.
- **프로그래밍 언어의 이점 활용**: 타입 검사, IDE 자동 완성, 조건/반복/함수 등 프로그래밍 언어의 기능을 인프라 정의에 활용하고자 하는 요구가 있었습니다.
- **높은 수준의 추상화**: 반복적인 인프라 패턴(VPC + 서브넷 + 보안 그룹 등)을 한 줄로 생성할 수 있는 고수준 추상화가 필요했습니다.

---

## 3. 작동 원리 / 핵심 개념

### 3.1 Construct

CDK의 핵심 빌딩 블록입니다. 하나 이상의 AWS 리소스를 캡슐화한 클래스이며, 세 가지 수준으로 나뉩니다.

| 수준 | 설명 | 예시 |
|------|------|------|
| **L1 (Cfn)** | CloudFormation 리소스와 1:1 대응. 모든 속성을 직접 지정 | `CfnBucket` |
| **L2 (기본)** | 합리적 기본값과 편의 메서드 제공. 가장 많이 사용 | `Bucket` |
| **L3 (패턴)** | 여러 리소스를 조합한 일반적 아키텍처 패턴 | `LambdaRestApi` |

```typescript
import * as s3 from 'aws-cdk-lib/aws-s3';

// L2 Construct - 합리적 기본값이 자동 적용됨
const bucket = new s3.Bucket(this, 'MyBucket', {
  versioned: true,
  encryption: s3.BucketEncryption.S3_MANAGED,
  removalPolicy: cdk.RemovalPolicy.DESTROY,
});
```

L2 Construct를 사용하면 CloudFormation에서 수십 줄이 필요한 설정을 몇 줄로 표현할 수 있습니다.

### 3.2 Stack과 App

- **Stack**: 배포의 단위입니다. 하나의 Stack은 하나의 CloudFormation 스택에 대응합니다.
- **App**: 여러 Stack을 묶는 최상위 컨테이너입니다.

```typescript
const app = new cdk.App();

// 네트워크와 애플리케이션을 별도 스택으로 분리
new NetworkStack(app, 'NetworkStack');
new ApplicationStack(app, 'AppStack');

app.synth();
```

### 3.3 합성과 배포 흐름

```
CDK 코드(TypeScript 등)
    ↓ cdk synth
CloudFormation 템플릿(JSON/YAML)
    ↓ cdk deploy
AWS 리소스 생성/변경
```

1. `cdk synth`: CDK 코드를 CloudFormation 템플릿으로 변환
2. `cdk diff`: 현재 배포된 상태와의 차이점 표시 ([[Terraform]]의 `plan`과 유사)
3. `cdk deploy`: CloudFormation을 통해 실제 배포

### 3.4 프로그래밍 언어의 활용

CDK의 가장 큰 장점은 프로그래밍 언어의 기능을 그대로 사용할 수 있다는 점입니다.

```typescript
// 반복문으로 여러 환경 생성
for (const env of ['dev', 'staging', 'prod']) {
  new AppStack(app, `App-${env}`, {
    environment: env,
    instanceCount: env === 'prod' ? 3 : 1,
  });
}
```

[[CloudFormation]]의 `Conditions`이나 `Fn::If`로는 표현하기 어려운 로직을 자연스럽게 작성할 수 있습니다.

---

## 4. 장점 및 이점

- **프로그래밍 언어 활용**: 타입 검사, IDE 자동 완성, 리팩터링 등 개발 도구의 지원을 받을 수 있습니다.
- **높은 추상화**: L2/L3 Construct를 통해 복잡한 인프라 패턴을 간결하게 표현할 수 있습니다.
- **CloudFormation 호환**: 기존 CloudFormation 스택과 공존할 수 있으며, 점진적 마이그레이션이 가능합니다.
- **테스트 가능**: 단위 테스트로 인프라 코드를 검증할 수 있습니다. 생성될 리소스의 속성을 테스트 코드에서 확인할 수 있습니다.
- **코드 재사용**: Construct를 npm이나 PyPI 패키지로 배포하여 팀 간 공유할 수 있습니다.

---

## 5. 한계점 및 고려사항

- **AWS 전용**: AWS 이외의 클라우드는 지원하지 않습니다. 멀티 클라우드가 필요하면 [[Terraform]]을 고려해야 합니다.
- **CloudFormation 제약 상속**: CDK는 내부적으로 CloudFormation을 사용하므로, CloudFormation의 리소스 제한(스택당 500개), 느린 롤백 등의 제약을 그대로 갖습니다.
- **디버깅 복잡성**: 오류 발생 시 CDK 코드, 생성된 CloudFormation 템플릿, AWS 실행 단계 중 어디서 문제가 발생했는지 파악이 어려울 수 있습니다.
- **버전 관리**: CDK와 Construct 라이브러리의 버전 업데이트가 빈번하며, 메이저 업데이트 시 호환성 문제가 발생할 수 있습니다.

---

## 관련 문서

- [[IaC]] - 상위 개념: 인프라를 코드로 관리하는 방법론
- [[CloudFormation]] - CDK가 내부적으로 사용하는 AWS 네이티브 IaC 서비스
- [[Terraform]] - 멀티 클라우드 지원 IaC 도구, CDK와 자주 비교됨
- [[ECS]] - CDK로 관리하는 대표적 AWS 컨테이너 서비스

---

## 참고 자료

- [AWS CDK Documentation](https://docs.aws.amazon.com/cdk/) - 공식 문서
- [Construct Hub](https://constructs.dev/) - 커뮤니티 Construct 라이브러리

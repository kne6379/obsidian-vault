---
created: 2026-03-08
updated: 2026-03-08
tags: [concept, devops, cloud, container]
status: done
---

# ECR (Elastic Container Registry)

> AWS에서 제공하는 완전 관리형 컨테이너 이미지 레지스트리로, [[Docker]] 이미지를 안전하게 저장·관리·배포할 수 있도록 지원합니다.

---

## 1. 정의

Amazon ECR(Elastic Container Registry)은 AWS의 완전 관리형 컨테이너 이미지 레지스트리 서비스입니다. [[Docker]] 이미지 및 OCI(Open Container Initiative) 호환 아티팩트를 저장하고, [[ECS]], EKS, Lambda 등 AWS 컴퓨팅 서비스에 배포할 수 있습니다.

인프라 관리 없이 이미지를 안전하게 저장하며, IAM 기반 접근 제어와 이미지 암호화를 기본 제공합니다.

---

## 2. 등장 배경 및 필요성

- **Docker Hub의 한계**: 공개 레지스트리인 Docker Hub는 비공개 이미지 저장에 제한이 있고, 기업 환경에서 요구하는 세밀한 접근 제어와 보안 정책을 적용하기 어렵습니다.
- **AWS 생태계 통합 필요**: [[ECS]]나 EKS에서 컨테이너를 실행하려면 이미지를 가져와야 합니다. AWS 내부 네트워크에서 이미지를 가져오면 외부 레지스트리 대비 속도가 빠르고 데이터 전송 비용이 절감됩니다.
- **보안 및 컴플라이언스**: 기업 환경에서는 이미지에 대한 취약점 스캔, 접근 로그 추적, 암호화 등 보안 요구사항을 충족해야 합니다.

---

## 3. 핵심 구성 요소

### 3.1 레지스트리 (Registry)

AWS 계정마다 자동으로 생성되는 최상위 단위입니다. 프라이빗 레지스트리와 퍼블릭 레지스트리를 각각 제공합니다.

| 유형 | 설명 |
|------|------|
| **프라이빗 레지스트리** | IAM 정책으로 접근 제어. 기업 내부 이미지 저장에 사용 |
| **퍼블릭 레지스트리** | ECR Public Gallery를 통해 누구나 이미지를 다운로드 가능. 오픈소스 배포에 활용 |

### 3.2 리포지토리 (Repository)

이미지를 저장하는 단위입니다. 하나의 리포지토리에 동일 애플리케이션의 여러 버전(태그)을 저장합니다.

```
{계정ID}.dkr.ecr.{리전}.amazonaws.com/{리포지토리명}:{태그}
```

### 3.3 이미지 (Image)

리포지토리에 저장되는 컨테이너 이미지입니다. 태그와 다이제스트(SHA256 해시)로 식별됩니다.

### 3.4 수명 주기 정책 (Lifecycle Policy)

오래되거나 불필요한 이미지를 자동 삭제하는 규칙입니다. 저장 비용을 절감하고 리포지토리를 깔끔하게 유지할 수 있습니다.

---

## 4. 장점 및 이점

- **완전 관리형**: 레지스트리 인프라 운영이 불필요합니다. 가용성과 확장성을 AWS가 보장합니다.
- **AWS 서비스 통합**: [[ECS]], EKS, Lambda, CodeBuild, CodePipeline 등과 네이티브 통합되어 CI/CD 파이프라인을 쉽게 구성할 수 있습니다.
- **보안**: IAM 기반 리포지토리별 접근 제어, 저장 시 AES-256 자동 암호화, 이미지 취약점 스캔(Amazon Inspector 연동)을 제공합니다.
- **빠른 이미지 풀**: AWS 내부 네트워크를 통해 이미지를 가져오므로 외부 레지스트리 대비 전송 속도가 빠르고 비용이 절감됩니다.
- **크로스 리전/크로스 계정 복제**: 이미지를 다른 리전이나 다른 AWS 계정으로 자동 복제할 수 있어 멀티 리전 배포에 유리합니다.

---

## 5. 한계점 및 고려사항

- **AWS 종속**: AWS 외부 환경에서 이미지를 사용하려면 별도의 인증 절차가 필요합니다. 멀티 클라우드 환경에서는 Docker Hub나 GitHub Container Registry 등을 병행 검토해야 합니다.
- **인증 토큰 만료**: ECR 인증 토큰은 12시간 후 만료됩니다. CI/CD 파이프라인에서 `aws ecr get-login-password` 명령을 주기적으로 실행해야 합니다.
- **비용 구조**: 저장 용량(GB/월)과 데이터 전송량에 따라 과금됩니다. 수명 주기 정책을 설정하지 않으면 오래된 이미지가 누적되어 비용이 증가합니다.

---

## 6. 실무 적용 가이드

### 6.1 기본 워크플로우

```
Dockerfile → docker build → docker tag → docker push → ECR 리포지토리
                                                              ↓
                                                    ECS/EKS에서 pull하여 실행
```

### 6.2 주요 CLI 명령어

```bash
# ECR 로그인
aws ecr get-login-password --region ap-northeast-2 | \
  docker login --username AWS --password-stdin {계정ID}.dkr.ecr.ap-northeast-2.amazonaws.com

# 리포지토리 생성
aws ecr create-repository --repository-name my-app

# 이미지 태그 및 푸시
docker tag my-app:latest {계정ID}.dkr.ecr.ap-northeast-2.amazonaws.com/my-app:latest
docker push {계정ID}.dkr.ecr.ap-northeast-2.amazonaws.com/my-app:latest
```

### 6.3 수명 주기 정책 예시

최근 10개 이미지만 유지하고 나머지는 자동 삭제하는 정책입니다.

```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "최근 10개 이미지만 유지",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": { "type": "expire" }
    }
  ]
}
```

### 6.4 ECR vs Docker Hub vs GitHub Container Registry

| 구분 | ECR | Docker Hub | GHCR |
|------|-----|------------|------|
| **관리** | AWS 완전 관리형 | SaaS | GitHub 관리형 |
| **접근 제어** | IAM 기반 | Docker Hub 계정 | GitHub 권한 |
| **AWS 통합** | 네이티브 | 수동 설정 필요 | 수동 설정 필요 |
| **비공개 저장소** | 무제한 | 무료 1개, 이후 유료 | 무제한 (GitHub 플랜) |
| **적합한 환경** | AWS 중심 배포 | 오픈소스/범용 | GitHub Actions CI/CD |

---

## 관련 문서

- [[Docker]] - ECR에 저장되는 컨테이너 이미지 기술
- [[ECS]] - ECR에서 이미지를 가져와 컨테이너를 실행하는 오케스트레이션 서비스

---

## 참고 자료

- [Amazon ECR 공식 문서](https://docs.aws.amazon.com/ko_kr/AmazonECR/latest/userguide/what-is-ecr.html) - AWS 공식 가이드
- [Amazon ECR Public Gallery](https://gallery.ecr.aws/) - 퍼블릭 이미지 저장소

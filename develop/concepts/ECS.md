---
created: 2026-02-02
updated: 2026-02-02
tags: [concept, devops, cloud, container]
status: done
---

# ECS (Elastic Container Service)

> AWS에서 제공하는 완전 관리형 컨테이너 오케스트레이션 서비스로, [[Docker]] 컨테이너 애플리케이션을 클러스터에서 쉽게 배포, 관리, 확장할 수 있도록 지원합니다.

---

## 1. 정의

Amazon ECS(Elastic Container Service)는 AWS의 완전 관리형 컨테이너 오케스트레이션 서비스입니다. 컨트롤 플레인을 직접 관리하는 복잡한 과정 없이 컨테이너 워크로드를 실행하고 확장할 수 있습니다.

ECS는 AWS 구성과 운영 모범 사례가 내장되어 있으며, Amazon ECR(컨테이너 레지스트리), ALB(로드밸런서), CloudWatch 등 AWS 서비스들과 긴밀하게 통합됩니다.

---

## 2. 등장 배경 및 필요성

- **컨테이너 오케스트레이션의 복잡성:** [[Docker]] 컨테이너를 대규모로 운영하려면 배포, 스케일링, 장애 복구 등을 관리해야 하는데, 이를 직접 구현하기는 복잡합니다.

- **Kubernetes의 높은 학습 곡선:** Kubernetes(EKS)는 강력하지만 학습 곡선이 높고 운영 오버헤드가 큽니다. AWS 생태계 내에서 더 단순한 솔루션이 필요했습니다.

- **AWS 네이티브 통합:** AWS 서비스들과 깊이 통합된 컨테이너 오케스트레이션이 필요한 경우, ECS가 더 자연스러운 선택입니다.

---

## 3. 핵심 구성 요소

### 3.1 Cluster (클러스터)

컨테이너 인스턴스들을 그룹화하는 논리적 단위입니다. 클러스터 내에서 Task와 Service가 실행됩니다.

### 3.2 Task Definition (작업 정의)

애플리케이션을 구성하는 컨테이너를 정의하는 JSON 템플릿입니다. 다음을 지정합니다:
- 컨테이너 이미지 (ECR URI)
- CPU/메모리 요구사항
- 포트 매핑
- 환경 변수
- 볼륨 마운트
- IAM 역할

### 3.3 Task (작업)

Task Definition을 기반으로 실제 실행되는 컨테이너 인스턴스입니다. 하나의 Task는 1개 이상의 컨테이너로 구성될 수 있으며, 같은 Task 내 컨테이너들은 동일한 호스트에서 실행됩니다.

### 3.4 Service (서비스)

Task들의 생명주기를 관리하는 상위 개념입니다. 다음을 담당합니다:
- 지정된 수의 Task 유지 (Desired Count)
- 오토 스케일링
- 로드 밸런서(ALB/NLB) 연동
- 롤링 업데이트 / 블루-그린 배포

### 3.5 ECR (Elastic Container Registry)

AWS의 관리형 컨테이너 이미지 저장소입니다. ECS와 긴밀하게 통합되어 이미지 풀/푸시가 용이합니다.

---

## 4. 컴퓨팅 옵션 (Launch Type)

ECS에서 컨테이너를 실행할 인프라를 선택할 수 있습니다.

### 4.1 Fargate (서버리스)

| 항목 | 설명 |
|------|------|
| **관리 주체** | AWS가 모든 인프라 관리 (서버리스) |
| **과금** | 사용한 vCPU/메모리 기준 초 단위 과금 |
| **적합한 경우** | 트래픽 변동이 큰 워크로드, 단기 실행 작업, 운영 부담 최소화 |
| **한계** | GPU 미지원 (2025년 기준), 커스텀 AMI 불가 |

### 4.2 EC2

| 항목 | 설명 |
|------|------|
| **관리 주체** | 사용자가 EC2 인스턴스 직접 관리 |
| **과금** | EC2 인스턴스 비용 (예약/스팟 인스턴스 활용 가능) |
| **적합한 경우** | GPU 워크로드, 특수 하드웨어 필요, 장기 실행 고정 워크로드 |
| **장점** | 인스턴스 타입/AMI 자유 선택, 비용 최적화 여지 |

### 4.3 ECS Managed Instances (2025년 신규)

Fargate의 운영 편의성과 EC2의 유연성을 결합한 옵션입니다. AWS가 인프라를 관리하면서도 GPU 등 다양한 EC2 인스턴스 타입을 사용할 수 있습니다.

---

## 5. ECS vs EKS 비교

| 구분 | ECS | EKS |
|------|-----|-----|
| **오케스트레이션** | AWS 자체 방식 | Kubernetes |
| **학습 곡선** | 낮음 | 높음 |
| **AWS 통합** | 네이티브, 긴밀함 | 통합되나 Kubernetes 방식 |
| **이식성** | AWS 종속 | 멀티 클라우드 이식 용이 |
| **컨트롤 플레인 비용** | 무료 | 클러스터당 $0.10/시간 |
| **적합한 팀** | AWS 중심, K8s 경험 적음 | K8s 경험 있음, 멀티 클라우드 고려 |

---

## 6. 장점 및 이점

- **운영 단순화:** 컨트롤 플레인 관리 불필요. AWS가 가용성, 확장성, 보안을 처리합니다.

- **AWS 서비스 통합:** IAM, CloudWatch, ALB, ECR, CodePipeline 등과 네이티브 통합됩니다.

- **유연한 컴퓨팅 옵션:** Fargate(서버리스)와 EC2(자체 관리) 중 워크로드에 맞게 선택하거나 혼합할 수 있습니다.

- **비용 효율:** Fargate는 초 단위 과금, EC2는 스팟/예약 인스턴스 활용으로 비용 최적화가 가능합니다.

---

## 7. 한계점 및 고려사항

- **AWS 종속:** ECS는 AWS 전용 서비스입니다. 멀티 클라우드 전략이나 온프레미스 이전을 고려한다면 EKS(Kubernetes)가 더 적합합니다.

- **Fargate 제약:** GPU 워크로드, 커스텀 커널/AMI가 필요한 경우 EC2 Launch Type을 사용해야 합니다.

- **고급 네트워킹:** 서비스 메시, 복잡한 네트워크 정책이 필요한 경우 Kubernetes(EKS)가 더 풍부한 옵션을 제공합니다.

---

## 8. 실무 적용 가이드

### 8.1 선택 기준

```
AWS 중심 + 운영 단순화 → ECS + Fargate
GPU/특수 하드웨어 → ECS + EC2
멀티 클라우드/K8s 경험 → EKS
```

### 8.2 일반적인 아키텍처

```
ECR (이미지 저장)
    ↓
ECS Cluster
    ├── Service A (Fargate) ─── ALB ─── 사용자
    └── Service B (Fargate) ─── 내부 통신
```

---

## 관련 문서

- [[Docker]] - ECS가 오케스트레이션하는 컨테이너 기술
- [[API Gateway]] - ECS 서비스 앞단에 배치하여 라우팅/인증 처리
- [[IaC]] - ECS 인프라를 코드로 관리하는 방법론
- [[Terraform]] - ECS를 프로비저닝하는 대표적 IaC 도구
- [[CloudFormation]] - AWS 네이티브 IaC로 ECS 관리

---

## 참고 자료

- [Amazon ECS 공식 문서](https://docs.aws.amazon.com/ko_kr/AmazonECS/latest/developerguide/Welcome.html) - AWS 공식 가이드
- [Amazon ECS 소개 - NDS Cloud Tech Blog](https://tech.cloud.nongshim.co.kr/blog/aws/1706/) - ECS 구성요소 설명
- [ECS vs EKS vs Fargate 비교 (2025)](https://dasroot.net/posts/2025/12/aws-container-services-ecs-vs-eks-vs-fargate-2025/) - 컨테이너 서비스 비교
- [Fargate vs EC2 Launch Type 비교](https://towardsthecloud.com/blog/amazon-ecs-vs-aws-fargate) - Launch Type 선택 가이드

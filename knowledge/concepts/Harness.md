---
created: 2026-03-17
updated: 2026-03-17
tags: [concept, devops, cicd, cloud]
status: done
---

# Harness

> AI 기반 소프트웨어 딜리버리 플랫폼으로, CI/CD, 보안, 인프라 관리, 비용 최적화를 통합 제공하는 엔터프라이즈급 DevOps 솔루션입니다.

---

## 1. 정의

Harness는 소프트웨어 딜리버리 라이프사이클 전반을 자동화하는 AI 기반 DevOps 플랫폼입니다. 단순한 CI/CD 도구를 넘어, 보안 테스트 오케스트레이션, 인프라 코드 관리, 내부 개발자 포털, 카오스 엔지니어링까지 포괄하는 통합 플랫폼으로 발전했습니다.

SaaS와 온프레미스 배포를 모두 지원하며, AI를 활용한 테스트 인텔리전스, 배포 검증, 자동 롤백 등이 핵심 차별점입니다.

---

## 2. 등장 배경 및 필요성

기존 CI/CD 도구들이 가진 한계를 해결하기 위해 등장했습니다.

- **Jenkins 유지보수 부담**: Jenkins는 유연하지만 플러그인 관리, 스케일링, 보안 설정에 2~5명의 전담 엔지니어가 필요한 경우가 많습니다. 도구 자체를 유지하는 데 지나치게 많은 리소스가 소모됩니다.
- **파편화된 DevOps 도구 체인**: CI, CD, 보안 스캐닝, 인프라 관리, 비용 관리가 각각 다른 도구로 운영되면서 통합과 일관성 확보가 어렵습니다.
- **수동 배포 검증의 한계**: 배포 후 이상 징후를 사람이 모니터링하고 판단하는 방식은 속도와 정확도에 한계가 있습니다. 특히 마이크로서비스 환경에서는 서비스 간 영향도 파악이 어렵습니다.

---

## 3. 작동 원리 / 핵심 개념

### 3.1 플랫폼 아키텍처

Harness는 세 가지 핵심 컴포넌트로 구성됩니다.

- **Harness Manager(컨트롤 플레인)**: 파이프라인 설정, 오케스트레이션, 정책 관리를 담당합니다. SaaS 또는 자체 호스팅으로 운영 가능합니다.
- **Harness Delegate**: 대상 환경(쿠버네티스 클러스터, 클라우드 계정 등)에 설치되는 경량 에이전트입니다. 실제 배포, 빌드, 검증 작업을 수행합니다.
- **파이프라인 계층 구조**: Pipeline → Stage → Step의 3단 구조로 워크플로우를 구성합니다. 순차 및 병렬 실행을 모두 지원합니다.

### 3.2 핵심 모듈

| 모듈 | 설명 |
|------|------|
| CI (Continuous Integration) | 컨테이너 기반 빌드, Test Intelligence로 테스트 주기 80% 단축 |
| CD (Continuous Delivery) | 카나리, 블루/그린, 롤링 배포 전략 기본 제공 |
| STO (Security Testing Orchestration) | SAST, SCA, DAST, 컨테이너 스캔 통합 오케스트레이션 |
| IaCM (Infrastructure as Code Management) | [[Terraform]], Terragrunt, AWS CDK 기반 인프라 자동화 |
| IDP (Internal Developer Portal) | Backstage 기반 내부 개발자 포털 |
| Database DevOps | 데이터베이스 스키마 변경 관리 및 환경 간 일관성 보장 |
| Artifact Registry | 아티팩트 관리, 스캐닝, 거버넌스 통합 |
| Supply Chain Security | 소프트웨어 공급망 보안 및 컴플라이언스 |

### 3.3 AI 기반 기능

- **Test Intelligence**: AI가 코드 변경 영향 범위를 분석하여 필요한 테스트만 선별 실행합니다. 테스트 시간을 최대 80% 단축합니다.
- **AI 배포 검증**: 로그와 APM 텔레메트리를 AI로 분석하여 배포 건강 상태를 자동 판별합니다. 이상 징후 감지 시 자동 롤백을 수행합니다.
- **AI DevOps Agent**: 자연어로 파이프라인을 생성하고 관리할 수 있는 AI 에이전트입니다. 모든 Harness 모듈에 걸쳐 파이프라인과 스테이지를 생성합니다.

### 3.4 거버넌스

- Open Policy Agent(OPA) 통합으로 유연한 정책 적용이 가능합니다.
- 엔터프라이즈급 RBAC, 배포 동결(Deployment Freeze), 감사 추적을 기본 제공합니다.

---

## 4. 장점 및 이점

- **낮은 유지보수 비용**: SaaS 모델에서는 인프라 관리가 불필요합니다. Jenkins 대비 운영 인력을 대폭 절감할 수 있습니다.
- **빌드 속도 향상**: 스마트 캐싱(Gradle, Bazel, Maven, Docker 레이어)과 Test Intelligence로 빌드 시간을 크게 단축합니다. 실제 사례로 Kajabi는 p90 빌드 타임을 50% 줄이면서 비용도 50% 절감했습니다.
- **내장 보안**: 시크릿 관리, 감사 추적, 정책 엔진이 기본 탑재되어 별도 플러그인 없이 보안 거버넌스를 확보할 수 있습니다.
- **멀티클라우드 지원**: AWS, GCP, Azure 등 주요 클라우드 프로바이더와 네이티브 통합됩니다.
- **시각적 파이프라인 편집기**: YAML 외에 비주얼 에디터를 제공하여 복잡한 워크플로우를 직관적으로 구성할 수 있습니다.

---

## 5. 한계점 및 고려사항

- **비용**: 엔터프라이즈 기능은 유료이며, 소규모 팀에게는 과도한 비용이 될 수 있습니다. GitHub Actions나 Jenkins 대비 진입 비용이 높습니다.
- **학습 곡선**: 모듈이 많고 개념이 풍부하여 초기 학습에 시간이 필요합니다. Jenkins의 Groovy나 GitHub Actions의 YAML보다 플랫폼 자체에 대한 이해가 더 요구됩니다.
- **쿠버네티스 네이티브 워크플로우 제한**: 일부 팀은 쿠버네티스 환경에서 ArgoCD나 Flux 같은 GitOps 네이티브 도구가 더 적합하다고 느낄 수 있습니다.
- **벤더 종속성**: 통합 플랫폼의 특성상 Harness 생태계에 대한 의존도가 높아질 수 있습니다.

---

## 6. 실무 적용 가이드

### 6.1 경쟁 도구 비교

| 기준 | Harness | Jenkins | GitHub Actions |
|------|---------|---------|----------------|
| 유형 | 상용 플랫폼 | 오픈소스 | 프리미엄(GitHub) |
| 호스팅 | SaaS + 온프레미스 | 자체 호스팅 전용 | SaaS + 셀프호스티드 러너 |
| 파이프라인 설정 | 비주얼 에디터 + YAML | Groovy(Jenkinsfile) | YAML |
| 유지보수 | 낮음(매니지드) | 높음 | 낮음 |
| 확장성 | 내장 오토스케일링 | 수동 구성 | 클라우드 호스티드 러너 |
| 보안 | 네이티브 시크릿, RBAC, 감사 | 플러그인 의존 | 내장 시크릿, OIDC |
| 적합 대상 | 엔터프라이즈 규모 CD | 복잡한 커스텀 워크플로우 | GitHub 중심 팀 |

### 6.2 도입 판단 기준

다음 조건에 해당하면 Harness 도입을 검토할 만합니다.

- 멀티클라우드 또는 멀티서비스 배포를 운영하는 경우
- Jenkins 유지보수에 과도한 리소스가 투입되는 경우
- 배포 검증과 롤백을 자동화하고 싶은 경우
- CI/CD, 보안, 인프라 관리를 단일 플랫폼으로 통합하고 싶은 경우

반면, GitHub 중심의 소규모 팀이라면 GitHub Actions가, 극도의 커스터마이징이 필요하거나 에어갭 환경이라면 Jenkins가 더 적합할 수 있습니다.

---

## 관련 문서

- [[Docker]] - Harness CI의 컨테이너 기반 빌드 환경
- [[쿠버네티스]] - Harness CD의 주요 배포 대상 오케스트레이션 플랫폼
- [[ECS]] - AWS 환경에서의 Harness CD 배포 대상

---

## 참고 자료

- [Harness 공식 사이트](https://www.harness.io/) - 플랫폼 개요 및 모듈 소개
- [Harness Developer Hub](https://developer.harness.io/) - 공식 문서 및 튜토리얼
- [Harness CI vs Jenkins](https://www.harness.io/comparison-guide/harness-ci-vs-jenkins) - 공식 비교 가이드
- [Harness CI vs GitHub Actions](https://www.harness.io/comparison-guide/harness-ci-vs-github-actions) - 공식 비교 가이드
- [Harness GitHub Repository](https://github.com/harness/harness) - 오픈소스 버전

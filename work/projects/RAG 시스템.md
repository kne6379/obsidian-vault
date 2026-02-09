---
created: 2026-02-08
updated: 2026-02-08
tags: [project, backend, ai, rag]
status: active
---

# RAG 시스템

## 개요

기존 문제 데이터셋과 참고 자료를 기반으로 교육용 문제(질문, 답변, 해설)를 자동 생성하고, AI Judge가 품질을 자동 평가하는 RAG(Retrieval-Augmented Generation) 시스템입니다.

**기간**: 2025.01 ~ 현재
**인원**: 백엔드 2인 개발
**역할**: 백엔드 설계 및 전체 구현, 프론트엔드 구현, 인프라 구성

---

## 기술 스택

| 분류 | 기술 |
|------|------|
| Backend | NestJS, TypeScript, TypeORM, PostgreSQL, pgvector |
| Frontend | React, Vite, React Query, Tailwind CSS |
| AI/LLM | Gemini API, OpenAI Embedding, OpenRouter |
| Validation | Zod, class-validator |
| Logging | Winston, Slack Webhook |
| Infra | Docker, Nginx, AWS EC2 |

---

## 프로젝트 규모

| 지표 | 수치 |
|------|------|
| Feature 모듈 | 13개 |
| 엔티티 (데이터 모델) | 24개 |
| 외부 프로바이더 | 3개 |

---

## 프로젝트 배경

교육 콘텐츠 제작 현장에서 다음 문제를 해결하기 위해 시작한 프로젝트입니다.

- **문제 제작 비용 과다**: 전문가가 수작업으로 문제를 만드는 데 많은 시간과 비용 소요
- **포맷 비일관성**: 여러 출제자가 만든 문제의 형식이 제각각
- **품질 검증 부재**: 생성된 문제의 정확도, 일관성 등을 체계적으로 검증할 수단 부족
- **참고 자료 활용 미흡**: 교재/교안 등 참고 자료를 문제 생성에 체계적으로 반영하지 못함

---

## 아키텍처

### 레이어 구조

```
클라이언트 (React) → API 레이어 (NestJS Controllers)
                      → 서비스 레이어 (비즈니스 로직)
                        → 프로바이더 레이어 (LLM, Embedding, Chunking)
                          → 데이터 레이어 (PostgreSQL + pgvector)
```

### 모듈 구조

| 모듈 | 역할 |
|------|------|
| Question | 문제 생성 파이프라인 오케스트레이션 (핵심 모듈) |
| Format | 포맷 자동 발견 및 CRUD 관리 |
| Resource | 참고 자료 청킹, 임베딩, 벡터 검색 |
| Judge | 문제 품질 평가 및 포맷 준수도 검증 |
| Cost | AOP 기반 비용 추적 (데코레이터 + 이벤트) |
| Prompt | DB 기반 프롬프트 템플릿 관리 |
| Organization | 멀티테넌시 조직 관리 |
| LlmModel | LLM 모델 정보 및 토큰 단가 관리 |
| Feedback | 사용자 피드백 수집 |

### 프로바이더 패턴

LLM, 임베딩, 청킹 등 외부 서비스를 인터페이스 기반 프로바이더 패턴으로 추상화하여 교체 가능하게 설계했습니다.

- **LLM Provider**: `BaseProvider` 추상 클래스 → `GeminiProvider`(생성), `OpenRouterProvider`(평가)
- **Embedding Provider**: `IEmbeddingProvider` 인터페이스 → `OpenAIEmbeddingProvider`
- **Chunking Provider**: `IChunkingProvider` 인터페이스 → `ParagraphChunkingProvider`

---

## 내가 담당한 기능

### 1. 포맷 자동 발견 (Format Discovery)

기존 문제 데이터셋을 LLM으로 분석하여 구조적 패턴(객관식, 단답형, 빈칸 채우기 등)을 자동 식별하고, 재사용 가능한 포맷 정의로 저장합니다.

**구현 포인트:**
- 기존 문제들을 Gemini LLM에 전달하여 컴포넌트 구조(지시문, 지문, 선택지, 해설 등)와 순서를 추출
- 발견된 포맷에 신뢰도 점수(0~1)를 부여하고, 관리자 승인 프로세스를 거쳐 사용
- Zod 스키마 기반 LLM 출력 검증으로 구조화된 JSON 응답 보장

### 2. RAG 기반 문제 생성 파이프라인

포맷 정의 + 참고 자료 + 예제 문제를 조합하여 LLM으로 새로운 문제를 생성하는 핵심 파이프라인입니다.

**생성 흐름:**
```
포맷 로드 → pgvector 벡터 검색(참고 자료) → 프롬프트 조립 → Gemini LLM 생성 → Zod 스키마 검증 → 저장
```

**구현 포인트:**
- pgvector 코사인 유사도 검색으로 주제 관련 참고 자료 청크를 검색 (top-k 설정 가능)
- 참고 자료 텍스트를 문단 단위로 청킹 후 OpenAI text-embedding-3-small로 1536차원 벡터 임베딩
- `reference_type` 옵션으로 참고 자료 활용 방식 제어 (참고+자체생성 / 참고자료만 / 참고 없음)
- 생성 시 사용된 참고 자료 청크와 유사도 점수를 `GenerationReference`로 추적

### 3. Self-Refine 기반 2단계 생성-검증 루프 (AI Judge)

생성된 문제를 AI Judge가 평가하고, 실패 시 **Judge의 평가 이유(reason)와 이전 생성 결과를 다음 프롬프트에 주입**하여 점진적으로 품질을 개선하는 Self-Refine 패턴을 구현했습니다.

**Self-Refine 흐름:**
```
생성 → Judge 평가 → 실패 시 {failureInfo} + {previousGeneratedQuestion}를 프롬프트에 주입 → 재생성
```

**Stage 1 - 문제 품질 평가 (최대 3회):**
- 정확도(accuracy), 관련성(relevance), 일관성(coherence), 논리성(consistency) 4개 차원 평가
- Judge가 각 차원별 점수(-1~10)와 함께 실패 이유 문자열을 반환
- 모든 점수 8점 이상 시 Stage 2로 진행, 미달 시 실패 이유 + 이전 생성 결과를 프롬프트에 포함하여 재생성

**Stage 2 - 포맷 준수도 검증 (최대 3회):**
- 포맷명 일치, 컴포넌트 준수도, 구조적 일관성, 선택지 유효성 검증
- 총 최대 6회(Stage 1: 3회 + Stage 2: 3회)의 LLM 호출로 품질 수렴

**구현 포인트:**
- 프롬프트 템플릿에 `{failureInfo}`와 `{previousGeneratedQuestion}` 변수를 두고, 재시도 시 동적으로 채워 LLM이 같은 실수를 반복하지 않도록 유도
- 생성-평가 모델 분리: 생성은 Gemini, 평가는 OpenRouter로 별도 LLM을 사용하여 자기 편향(self-bias) 방지
- 모든 재시도마다 `retrialCount`를 비용 추적에 기록

### 4. AOP 기반 비용 추적 시스템

비즈니스 로직을 오염시키지 않으면서 모든 LLM API 호출의 토큰 사용량과 비용을 자동 추적합니다.

**구현 포인트:**
- `@BatchStart`, `@BatchEnd`, `@CostTracking` 커스텀 데코레이터로 AOP 방식 비용 추적
- NestJS EventEmitter 기반 이벤트 드리븐 아키텍처로 비용 이벤트 비동기 처리
- nestjs-cls를 활용한 요청 컨텍스트 기반 배치 관리 (동일 요청 내 여러 LLM 호출을 하나의 배치로 집계)
- 모델별 입력/출력 토큰 단가 기반 비용 자동 계산 (소수점 6자리 정밀도)
- 작업 유형별(생성, 평가, 포맷발견, 임베딩) 비용 분류 및 추적

### 5. 프롬프트 개발 방법론

**Judge LLM 우선 개발**
- 생성 LLM 프롬프트 개발 전, Judge(검증) LLM을 먼저 구축
- Evaluation 스크립트 작성하여 Judge LLM 성능 측정

**감별률 측정 및 시각화**
- 측정 항목별 조작 데이터 + 정상 데이터셋 준비
- Evaluation 결과를 DB에 저장
- SQL 기반 Retool 대시보드에서 감별률 시각화
- 감별률 기반으로 Judge LLM 프롬프트 튜닝

**생성 LLM 선정**
- Judge LLM을 통해 여러 생성 LLM의 출력 품질 평가
- 가장 높은 품질의 데이터를 생성하는 LLM 선정

### 6. 프론트엔드 구현

- React + Vite 기반 관리자 대시보드 구현
- React Query v5 기반 서버 상태 관리
- Tailwind CSS 기반 UI 구현

### 7. 인프라 구성

- Docker 멀티스테이지 빌드 구성
- Nginx 기반 프로덕션 배포 환경 구성
- Infisical 기반 시크릿 관리

---

## 데이터베이스 설계

### 핵심 테이블 구조

```
organizations (1)
├── questions (M)              # 기존 문제 (포맷 발견용)
├── generated_questions (M)    # LLM 생성 문제
│   ├── question_judge_results (1)   # 품질 평가 결과
│   ├── format_judge_results (1)     # 포맷 검증 결과
│   ├── generation_references (M)    # 참조한 리소스 청크
│   └── user_feedbacks (M)          # 사용자 피드백
├── format_definitions (M)     # 포맷 정의
├── resources (M)              # 참고 자료 원본
│   └── resource_chunks (M)    # 청크 + 벡터 임베딩 [vector(1536)]
└── batch_usage (M)            # 배치별 비용 집계
    └── api_usage (M)          # 개별 API 호출 비용
```

### 벡터 검색

- pgvector 확장으로 PostgreSQL 내에서 벡터 유사도 검색 수행
- 코사인 유사도(`<->` 연산자) 기반 top-k 검색
- 별도의 벡터 DB 없이 관계형 데이터와 벡터 검색을 단일 DB에서 처리

---

## 기술적 도전과 해결

### 1. LLM 출력의 구조화 문제

**문제**: LLM이 항상 유효한 JSON을 반환하지 않음

**해결**: Zod 스키마 기반 런타임 검증 + 자동 재시도 패턴을 BaseProvider에 구현

### 2. 비용 추적의 비침투성

**문제**: 모든 LLM 호출에 비용 추적 코드를 직접 넣으면 비즈니스 로직이 오염됨

**해결**: NestJS 데코레이터 + EventEmitter + CLS 조합으로 AOP 방식 구현

### 3. 생성 품질 일관성

**문제**: LLM이 포맷을 정확히 따르지 않거나, 단순 재시도로는 같은 실수 반복

**해결**: Self-Refine 패턴 적용. Judge 실패 reason과 이전 생성 결과를 다음 프롬프트에 주입. 생성 모델(Gemini)과 평가 모델(OpenRouter) 분리로 자기 편향 방지

### 4. 참고 자료의 효율적 검색

**문제**: 긴 참고 자료에서 주제에 관련된 부분만 정확히 찾아야 함

**해결**: 문단 기반 청킹(오버랩 포함) + OpenAI 임베딩 + pgvector 코사인 유사도 검색. PostgreSQL 단일 DB로 구현하여 운영 복잡도 감소

---

## 성과

- **24개 엔티티, 13개 모듈** 규모의 모듈러 아키텍처 설계 및 구현
- **Self-Refine 기반 2단계 생성-검증 루프**로 LLM 생성 품질 자동화 (4개 평가 차원 모두 8/10 이상)
- **AOP 기반 비용 추적**으로 비즈니스 로직 변경 없이 모든 LLM API 호출 비용 자동 집계
- 프로바이더 패턴으로 LLM/임베딩 모델 교체 용이성 확보
- Docker + Nginx 기반 프로덕션 배포 환경 구성

---

## 배운 점

- **LLM 애플리케이션의 핵심은 출력 검증**: 스키마 검증과 품질 평가를 반드시 파이프라인에 포함해야 함
- **AOP 패턴의 효용**: 횡단 관심사를 데코레이터와 이벤트로 분리하면 비즈니스 로직의 가독성과 유지보수성 향상
- **프로바이더 패턴의 유연성**: LLM 모델이 빠르게 변화하는 환경에서 인터페이스 기반 추상화는 모델 교체 비용을 크게 줄여줌
- **pgvector의 실용성**: 별도 벡터 DB 없이 PostgreSQL만으로 벡터 검색 구현 가능, 인프라 복잡도 감소

---

## 관련 문서

- [[문제생성엔진]] - 문제 생성 플랫폼
- [[RAG]] - RAG 기술 개념

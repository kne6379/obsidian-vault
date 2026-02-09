---
created: 2026-02-09
updated: 2026-02-09
tags: [project, backend, ai, python, langchain]
status: active
---

# QGen AI

## 개요

AI 기반 교육 콘텐츠(문제/지문) 자동 생성 및 품질 평가 서비스의 **LLM 통신 백엔드**입니다. 기존 NestJS/TypeScript 기반 SDK 직접 호출 구조를 **Python + LangChain + FastAPI** 기반으로 전면 교체하면서, 모듈 구조를 클린 아키텍처 원칙에 따라 리팩토링하는 마이그레이션 프로젝트입니다.

**기간**: 2025.12 ~ 현재
**역할**: 백엔드 아키텍처 설계 및 전체 구현, AI 개발 워크플로우 설계

---

## 기술 스택

| 분류        | 기술                                                             |
| --------- | -------------------------------------------------------------- |
| Language  | Python 3.12+                                                   |
| Framework | FastAPI, Pydantic v2                                           |
| ORM       | SQLAlchemy 2.0 (Async) + asyncpg                               |
| LLM 통합    | LangChain (실시간), OpenAI/Anthropic/Google GenAI SDK (Batch API) |
| Database  | PostgreSQL (Supabase)                                          |
| Storage   | Supabase Storage                                               |
| Cache     | Redis                                                          |
| Logging   | Loguru, Slack Webhook                                          |
| 비밀 관리     | Infisical                                                      |
| 패키지 관리    | uv                                                             |
| 린트/포맷     | ruff                                                           |
| 테스트       | pytest, pytest-asyncio                                         |
| AI 개발 도구  | Claude Code                                                    |

---

## 마이그레이션 배경

### Before (NestJS)

- NestJS 11 + TypeORM 0.3 + TypeScript
- `ai` 패키지 및 각 벤더 SDK를 직접 호출하여 LLM 통신
- 22개 도메인 모듈, 44개 DB 엔티티, ~25,700 LOC

### After (Python/FastAPI)

- FastAPI + SQLAlchemy 2.0 (Async) + Pydantic v2
- **LangChain 추상화 레이어** 도입으로 멀티 LLM 프로바이더 통합
- 클린 아키텍처 기반 계층 분리 (Controller → UseCase → Service → Provider/Repository)
- 6개 핵심 도메인으로 재구조화, async/await 전면 적용

### 마이그레이션 핵심 포인트

- 프레임워크 전환 (NestJS → FastAPI) 과정에서 **아키텍처 계층 재설계**
- SDK 직접 호출 → **LangChain 추상화** 도입으로 프로바이더 교체 비용 최소화
- TypeORM → **SQLAlchemy 2.0 Async ORM** 전환 (동일 Supabase PostgreSQL 공유)
- 배치 처리 오케스트레이션에 **AWS Step Functions** 도입 예정

---

## 아키텍처

### 계층 구조 (Clean Architecture)

```
app/
├── api/v1/              # [진입점] HTTP Controller
├── pipelines/           # [진입점] 배치 파이프라인 (Step Functions 연동 예정)
├── application/         # [UseCase] 비즈니스 흐름 조합
├── domain/              # [Service] 순수 비즈니스 로직
├── infrastructure/      # [Infra] 외부 연동 (DB, AI, Storage)
├── shared/              # [공통] 상수, Enum, Schema, 유틸리티
└── core/                # 설정, DB, DI, 미들웨어, 로거
```

**의존성 방향**: `api → application → domain → infrastructure` (역방향 의존 금지)

### 행위 기반 도메인 분리

도메인을 엔티티(데이터) 중심이 아닌 **행위(기능)** 중심으로 분리:

| 도메인 | 행위 | 비고 |
|--------|------|------|
| generation/ | 문제/지문 **생성** | 실시간 LLM 호출 |
| batch/ | 배치 **제출·결과 처리** | Batch API 오케스트레이션 |
| media/ | 이미지·음성 **생성** | AI 이미지, TTS |
| qc/ | 품질 **검증** | LLM 기반 QC |
| embedding/ | 임베딩 **생성** | 벡터 변환 |
| shared/ | 프롬프트 빌드, 응답 파싱 | 도메인 간 공유 행위 |

같은 `Question` 엔티티를 다루더라도 "생성"과 "배치 처리"는 서로 다른 도메인으로 분리됨. 이를 통해 각 도메인이 독립적으로 확장·변경 가능하며, 도메인 간 결합도를 최소화.

### UseCase — Facade 패턴

UseCase는 **Facade 패턴**을 적용한 진입점으로, 여러 Service를 조합하여 하나의 비즈니스 흐름을 캡슐화:

```
Controller
    ↓ 단일 호출
UseCase (Facade)  ← 복수 Service 조합, 트랜잭션 경계
    ├── ServiceA.method()
    ├── ServiceB.method()
    └── ServiceC.method()
```

- 외부(Controller)에서는 UseCase 하나만 호출하면 되고, 내부 Service 조합을 알 필요 없음
- UseCase 함수 하나만 읽으면 비즈니스 흐름 전체를 파악 가능
- Service 간 직접 호출 금지 — 반드시 UseCase를 통해 조합 (Service 간 결합 방지)

### 의존성 주입 패턴

```
Provider (싱글톤, @lru_cache)
    ↓ 생성자 주입
Service (요청별 팩토리, Session 주입)
    ↓ 호출
UseCase (Facade 함수, Service 조합)
    ↓ 호출
Controller (함수, FastAPI Depends)
```

- **Provider**: 외부 연동 클래스 (LLM, Storage 등), 상태 없이 싱글톤 재사용
- **Service**: 비즈니스 로직 클래스, DB Session을 포함하여 요청마다 새 인스턴스 생성
- **UseCase**: Facade 함수, 복수 Service를 조합하여 비즈니스 흐름 캡슐화
- **Controller**: 함수 형태, HTTP 요청/응답 처리 + UseCase 호출

### AI Provider 추상화

```
BaseLLMProvider (ABC)          → Claude, Gemini, OpenAI, OpenRouter
BaseBatchProvider (ABC)        → GeminiBatch (구현 완료), OpenAIBatch/ClaudeBatch (예정)
BaseImageProvider (ABC)        → GeminiImage
BaseTTSProvider (ABC)          → GeminiTTS
BaseEmbeddingProvider (ABC)    → OpenAIEmbedding
```

- 실시간 LLM은 **LangChain** 사용 (ChatOpenAI, ChatAnthropic, ChatGoogleGenerativeAI)
- Batch API는 LangChain 미지원으로 **각 벤더 SDK 직접 구현**
- Google SDK 동기 메서드는 `asyncio.to_thread`로 비동기 래핑

---

## 내가 담당한 기능

### 1. Generation (문제 생성)

- 다중 LLM 프로바이더 기반 실시간 문제/지문 생성 (Gemini, Claude, OpenAI, OpenRouter)
- Few-shot 프롬프팅: DB에서 예시 문제 3건을 자동 로드하여 프롬프트에 포함
- 프롬프트 템플릿 시스템: DB 기반 버전 관리, `{{variable}}` 플레이스홀더 치환
- 벌크 컨텍스트 로딩 시 **튜플 기반 캐싱**으로 중복 DB 쿼리 방지
- LLM 응답 후처리: JSON 코드블록 추출, LaTeX 이스케이프, answer 필드 타입 변환
- 체크섬 기반 중복 탐지

### 2. Batch (배치 처리)

**5단계 배치 워크플로우:**
1. 키워드 선택: 핑퐁 라운드로빈 + 다중 필드 정렬(미사용 우선 → 교차 완성도 → 사용 빈도 → LRU)
2. JSONL 빌드: 프로바이더별 요청 포맷으로 변환
3. 업로드 및 저장: Supabase Storage 업로드 + DB 메타데이터 저장
4. 프로바이더 제출: Batch API 호출, 상태 추적 시작
5. 결과 다운로드: 폴링 → 결과 파싱 → 성공/실패 카운트 → Storage 저장

**키워드 선택 알고리즘:**
- 카테고리별 공정 분배
- 5단계 다중 필드 정렬(미사용 우선 → 교차 완성도 → 사용 빈도 → LRU → 생성 횟수)
- 모드 붕괴(mode collapse) 방지

### 3. Media (이미지 / TTS)

- AI 이미지 생성: Gemini 기반, base64 → Storage 업로드 → Asset DB 저장
- **멀티 스피커 TTS**: 성별 기반 화자 매핑, 대화형 음성 합성
- Listening Script 기반 자동 음성 생성

### 4. Shared (공유 서비스)

**프롬프트 관리:**
- DB 기반 프롬프트 템플릿 로드
- 변수 추출/검증/치환
- LRU 캐시로 중복 쿼리 방지

**응답 파싱:**
- 4단계 전처리 파이프라인 (코드블록 추출 → 백틱 제거 → 줄바꿈 변환 → LaTeX 이스케이프)
- Pydantic 스키마 검증

### 5. 운영 안정성

**로깅 시스템 (Loguru):**
- 구조화 로그: `{timestamp} | {level} | {file}:{function}:{line} | {request_id} | {message}`
- ContextVar 기반 요청 추적 (request_id: UUID v7)
- WARNING 이상 Slack 웹훅 자동 알림

**미들웨어:**
- Pure ASGI 미들웨어 (BaseHTTPMiddleware 미사용으로 성능 최적화)
- ContextVar 기반 스레드 안전 컨텍스트 전파

**에러 처리:**
- `BusinessException` + `ErrorCode` enum 기반 표준화된 에러 응답

---

## Claude Code 기반 AI 개발 워크플로우

프로젝트 전반에 Claude Code를 활용한 AI 기반 개발 워크플로우를 설계하고 운영합니다. CLAUDE.md를 아키텍처 소스 오브 트루스로 두고, 목적별 에이전트와 커맨드 시스템을 구축했습니다.

### 문서 체계

```
CLAUDE.md                          # 프로젝트 전체 아키텍처 가이드 (진입점)
.claude/
├── code-convention.md             # 코딩 표준
├── logging.md                     # 로깅 규칙
├── context/                       # 도메인별 상세 설계 컨텍스트
├── agents/                        # AI 에이전트 역할 정의 (6종)
└── commands/                      # 슬래시 커맨드 정의 (9종)
```

### 커스텀 에이전트 (6종)

| 에이전트 | 역할 |
|----------|------|
| architect | 아키텍처 설계 검토, ADR 출력 |
| code-reviewer | 8개 차원 코드 리뷰 + 심각도 분류 |
| migration-advisor | NestJS → Python 마이그레이션 조언 |
| test-writer | 테스트 코드 작성 (AAA 패턴) |
| pr-writer | PR 문서 자동 생성 |
| code-explainer | Python 코드 설명 (JS/TS 개발자 대상) |

### 슬래시 커맨드 (9종)

| 커맨드 | 기능 |
|--------|------|
| /issue | 이슈 생성 + 브랜치 자동 생성 |
| /commit | 컨벤션 기반 커밋 메시지 자동 생성 |
| /pr | PR 문서 자동 생성 |
| /review | AI 코드 리뷰 (8개 차원 + ruff 린트) |
| /test | 테스트 작성 및 실행 |
| /arch | 아키텍처 리뷰 (ADR 형식) |
| /migrate | NestJS 모듈 마이그레이션 |
| /new-domain | 새 도메인 생성 |
| /new-provider | 새 AI Provider 추가 |

### 워크플로우 흐름

```
/issue → 이슈 생성 + 브랜치 자동 생성
  ↓
코드 작성 (architect, code-explainer 참조)
  ↓
/review → AI 코드 리뷰
  ↓
/test → 테스트 작성 및 실행
  ↓
/commit → 컨벤션 커밋
  ↓
/pr → PR 문서 자동 생성
```

---

## 기술적 도전과 해결

### 1. 멀티 프로바이더 Batch API 통합

**문제**: 각 LLM 벤더의 Batch API 인터페이스와 데이터 포맷이 상이

**해결**: `BaseBatchProvider` 추상 클래스로 통합 인터페이스 정의, 프로바이더별 포맷 변환 로직 캡슐화

### 2. 키워드 선택 공정 분배 알고리즘

**문제**: 특정 키워드/카테고리에 생성이 편중되면 콘텐츠 다양성 저하 (mode collapse)

**해결**: 핑퐁 라운드로빈 + 5단계 다중 필드 정렬로 공정 분배

### 3. Sync SDK의 비동기 통합

**문제**: Google GenAI SDK 일부 메서드가 동기 전용이나, 서비스 전체가 async 기반

**해결**: `asyncio.to_thread()`로 blocking I/O를 이벤트 루프 외부 스레드에서 실행

### 4. LLM 응답 안정성 확보

**문제**: LLM이 불완전한 JSON, 코드블록 래핑, LaTeX 특수문자 등 비정형 응답 반환

**해결**: 4단계 전처리 파이프라인 + Pydantic 스키마 검증

### 5. 프레임워크 전환 시 DB 공존

**문제**: NestJS(TypeORM)와 Python(SQLAlchemy)이 동일 Supabase PostgreSQL을 공유

**해결**: SQLAlchemy 모델을 `sqlacodegen`으로 기존 스키마에서 자동 생성, 스키마 변경 없이 양쪽 공존

---

## 현재 진행 상황

### 구현 완료

- 클린 아키텍처 4계층 구조 설계
- LLM Provider 추상화 (Gemini, Claude, OpenAI, OpenRouter)
- Gemini Batch API Provider
- 문제 생성, 이미지 생성, TTS 서비스
- Claude Code 에이전트 6종 + 커맨드 9종

### 구현 예정

- AWS Step Functions 오케스트레이션
- OpenAI/Claude Batch Provider
- QC (품질 검증) 서비스

---

## 성과

- NestJS 22개 모듈, ~25,700 LOC → **6개 핵심 도메인, 4계층 클린 아키텍처**로 재구조화
- **4종 LLM 프로바이더** 통합 추상화 레이어 구현
- **LangChain 도입**으로 프로바이더 교체 비용 최소화
- **Claude Code 기반 AI 개발 워크플로우** 구축 (에이전트 6종, 커맨드 9종)
- 문서 기반 아키텍처 관리 체계 수립

---

## 배운 점

- **클린 아키텍처의 실용성**: 계층 분리로 테스트와 프로바이더 교체가 용이해짐
- **LangChain의 장단점**: 실시간 LLM은 추상화가 유용하나, Batch API는 직접 구현 필요
- **AI 개발 워크플로우의 효용**: 에이전트와 커맨드를 통한 자동화로 개발 속도 및 일관성 향상
- **프레임워크 마이그레이션 전략**: sqlacodegen으로 기존 DB 스키마 활용, 점진적 전환 가능

---

## 관련 문서

- [[문제생성엔진]] - 기존 NestJS 기반 시스템
- [[RAG 시스템]] - 문제 평가 시스템

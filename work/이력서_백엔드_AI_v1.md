---
created: 2026-02-08
updated: 2026-02-09
tags: [resume, backend, ai]
status: draft
---

# 이력서 - 백엔드 개발자 (AI/LLM)

## 기본 정보

**포지션**: Backend Developer (AI/LLM)
**경력**: 1년 3개월 (2024.11 ~ 현재)

---

## 자기소개

AI 기반 교육 콘텐츠 생성 시스템을 설계하고 구현한 백엔드 개발자입니다. NestJS와 Python/FastAPI 기반으로 멀티 LLM Provider 추상화 아키텍처를 설계했으며, Self-Refine 패턴과 RAG 파이프라인으로 AI 생성 품질을 점진적으로 개선하는 시스템을 구축했습니다. 검증 LLM을 먼저 개발하고 감별률을 측정하여 생성 프롬프트를 최적화하는 방법론을 적용했습니다. 300명 이상 동시 접속 실시간 시험 시스템을 안정적으로 운영한 경험이 있습니다.

---

## 기술 스택

### Backend
- **Language**: TypeScript, Python
- **Framework**: NestJS, FastAPI
- **ORM**: TypeORM, SQLAlchemy 2.0 (Async)
- **Database**: PostgreSQL, Supabase

### AI/LLM
- **LLM**: Gemini API, OpenAI API, Claude API, OpenRouter
- **Framework**: LangChain
- **Vector DB**: pgvector
- **Image**: Gemini Imagen, DALL-E
- **TTS**: Gemini TTS

### Infra & Tools
- **Cloud**: AWS EC2
- **Storage**: Supabase Storage
- **Logging**: Winston, Morgan, Loguru, Slack Webhook
- **Validation**: Zod, Pydantic v2
- **Nocode**: Retool, Bubble
- **Container**: Docker, Nginx

---

## 학력

### 한양사이버대학교 | 응용소프트웨어공학과
**2025.03 ~ 현재** (3학년 재학 중)

---

## 교육

### 스파르타코딩클럽 | Node.js 백엔드 개발자 양성 과정
**2024.04 ~ 2024.08**

---

## 경력

### 큐레아 | Backend Developer
**2024.11 ~ 현재** (1년 3개월)

에듀테크 스타트업에서 AI 기반 교육 콘텐츠 생성 시스템 및 온라인 학습 플랫폼의 백엔드 전체를 설계하고 구현했습니다.

---

## 프로젝트

### 1. QGen AI
**기간**: 2025.12 ~ 현재
**역할**: 백엔드 아키텍처 설계 및 전체 구현
**기술**: Python, FastAPI, LangChain, SQLAlchemy 2.0, PostgreSQL

문제생성엔진의 LLM 통신부를 Python/FastAPI + LangChain으로 전면 재설계하는 마이그레이션 프로젝트입니다.

**마이그레이션 규모**: NestJS 22개 모듈, ~25,700 LOC → 6개 핵심 도메인, 4계층 아키텍처

**기술적 도전과 해결**:
- LLM 프로바이더마다 API 인터페이스가 상이하여 코드 중복 발생
  → Provider 패턴 + LangChain 추상화로 4개 프로바이더 통합, 교체 비용 최소화
- 문제 생성 파이프라인(프롬프트 빌드 → LLM 통신 → 멀티모달 생성 → QC)이 단일 서비스에 강결합
  → 행위 기반 도메인 분리로 각 단계를 독립 모듈화, API 단위 오케스트레이션 구조로 전환
- Service 간 직접 호출로 결합도 증가 및 의존성 관리 어려움
  → UseCase 레이어를 도입하여 Service 오케스트레이션, Service 간 호출 제거
- NestJS(TypeORM)와 Python(SQLAlchemy)이 동일 DB를 공유해야 하는 상황
  → sqlacodegen으로 기존 스키마에서 모델 자동 생성, 스키마 변경 없이 공존

**담당 기능**:
- 계층형 아키텍처 4계층 설계 (Controller → UseCase → Domain → Infra)
- UseCase: Facade 패턴으로 Service 오케스트레이션, Service 간 직접 호출 제거
- Infra: 포트-어댑터 패턴으로 Provider 교체 용이
- 행위 기반 도메인 분리 (생성/배치/미디어/QC/임베딩)
- DI 패턴 설계 (Provider 싱글톤 + Service 요청별 팩토리)
- Claude Code 기반 AI 개발 워크플로우 구축 (CLAUDE.md, 컨벤션, 코드 리뷰·PR·마이그레이션 에이전트)
---

### 2. 문제생성엔진 (QGen)
**기간**: 2025.07 ~ 2025.11
**역할**: 백엔드 전체 설계 및 구현
**기술**: NestJS, TypeScript, TypeORM, PostgreSQL, pgvector, Gemini/OpenAI/Claude API

**프로젝트 규모**: 27개 모듈, 44개 엔티티, 30개 서비스, 9개 프로바이더

**기술적 도전과 해결**:
- 수백~수천 건의 문항을 생성해야 하나 실시간 API 호출은 비용과 시간이 과다
  → JSONL 기반 Batch API 파이프라인 구축 (빌드 → 제출 → Staging Table 파싱)
- 특정 키워드/카테고리에 생성이 편중되어 콘텐츠 다양성 저하
  → 라운드 로빈 + 최소 사용 우선 알고리즘으로 키워드 균형 분배
- LLM 생성 품질을 객관적으로 측정할 방법 부재
  → 검증 LLM 우선 개발 → 조작 데이터로 감별률 측정 → 생성 프롬프트 최적화

**담당 기능**:
- 다중 LLM Provider 추상화 (실시간 + Batch API 이중 구조)
- 멀티모달 콘텐츠 생성 (이미지: Gemini Imagen/DALL-E, TTS: Gemini TTS)
- Vision Coordinate: Claude로 이미지 내 객체 바운딩 박스 좌표 자동 추출
- 44개 엔티티 데이터 모델링 (국어/영어/수학 3개 교과, 6개 세부 영역)
- Zod 스키마 기반 LLM 응답 검증 파이프라인
- 배치 비용/토큰 추적 시스템

---

### 3. RAG 시스템
**기간**: 2025.05 ~ 현재
**역할**: 백엔드 설계 및 전체 구현, 프론트엔드 구현, 인프라 구성
**기술**: NestJS, TypeScript, PostgreSQL, pgvector, React, Retool

**프로젝트 규모**: 13개 모듈, 24개 엔티티, 3개 프로바이더

**기술적 도전과 해결**:
- LLM이 같은 실수를 반복하여 단순 재시도로는 품질 개선 안됨
  → Self-Refine 패턴 적용: Judge 실패 reason + 이전 생성 결과를 다음 프롬프트에 주입
- 생성 모델이 자기 출력을 평가하면 자기 편향(self-bias) 발생
  → 생성(Gemini)과 평가(OpenRouter) 모델 분리
- 모든 LLM 호출에 비용 추적 코드를 넣으면 비즈니스 로직 오염
  → AOP 방식 `@CostTracking` 데코레이터 + EventEmitter로 비침투적 구현

**담당 기능**:
- 포맷 자동 발견 (Format Discovery): LLM으로 기존 문제 데이터셋에서 구조 패턴 자동 식별
- RAG 파이프라인: 포맷 로드 → pgvector 벡터 검색 → 프롬프트 조립 → 생성 → 검증
- Self-Refine AI Judge: 4개 차원 평가 (정확도/관련성/일관성/논리성)
- 프롬프트 개발 방법론: Evaluation 스크립트 → DB 저장 → Retool 시각화
- React + Vite 기반 관리자 대시보드
- Docker + Nginx 기반 프로덕션 배포 환경 구성

---

### 4. 라스쿨
**기간**: 2025.02 ~ 현재
**역할**: 데이터 설계 + 백엔드 API 개발
**기술**: Bubble Backend Workflow, Bubble Database, Data API
**협업**: KB금융그룹

KB금융그룹과 협업하여 소외계층 학생들의 교육을 지원하는 학습 관리 플랫폼입니다.

**기술적 도전과 해결**:
- 300명 이상 동시 접속 시 실시간 데이터 생성으로 서버 불안정
  → 시험 데이터 사전 생성 방식으로 전환하여 안정성 확보
- 교재 데이터에 맞춤법 오류 등 품질 문제 발생
  → LLM 기반 데이터 자동 교정 시스템 구축
- Bubble 플랫폼의 워크로드 제한으로 대규모 데이터 처리 어려움
  → Data API 활용으로 워크로드 최적화

**담당 기능**:
- 계정 관리 시스템 (강사-멘토-멘티 역할 기반 권한)
- 진단시험 시스템 (예약, 미응시자 관리, 재응시, 기록 보존)
- 디지털 교재 관리 (소단원→중단원→대단원 계층 구조 설계)
- 학습 대시보드 (진단시험 결과 + 학습 기록 통합, 종합 성적 시각화)
- 똑스 ↔ 라스쿨 연동 API 구현

---

### 5. 똑스
**기간**: 2024.11 ~ 현재
**역할**: 데이터 설계 + 백엔드 API 개발
**기술**: Bubble Backend Workflow, Bubble Database, Gemini/OpenAI API

온라인 시험 및 학습 플랫폼입니다. 문제 풀이, 기출 풀이, 오답노트, LMS 기능을 제공합니다.

**기술적 도전과 해결**:
- 모의고사 데이터 정합성 검증이 수작업으로 이루어져 오류 빈발
  → 자동 정합성 검사 시스템 구축
- 학습 자료가 체계화되지 않아 콘텐츠 관리 어려움
  → 데이터 구조 설계 및 DB 구축 (1분 요약, 5분 탐구, 용어 사전)
- AI 도구별 프롬프트 관리가 분산되어 유지보수 어려움
  → 프롬프트 DB 관리 시스템 구축

**담당 기능**:
- 온라인 모의고사 시스템 (API, 데이터베이스 구축, 채점)
- 문제풀이 엔진 (영어 듣기 평가, 수학 문제 풀이, OMR 패널 동기화)
- 학습 기능 (기출 풀이, 문제 저장, 오답노트)
- 학습 자료 시스템 (데이터 구조 설계, DB 구축, 온라인 열람)
- AI 학습 도구 15개+ (교과 공부용, 수행평가용, 프롬프트 DB 관리)
- LMS (학급 관리, 시험지 생성/배포, 스케줄링 개별 시험)

---

## 핵심 역량

### LLM/AI 시스템 설계
- 다중 LLM Provider 추상화 패턴 설계 (Gemini, OpenAI, Claude, OpenRouter)
- Self-Refine RAG 파이프라인 구현
- 프롬프트 개발 방법론: 검증 LLM 우선 개발 → 감별률 측정 → 생성 프롬프트 최적화
- 멀티모달 콘텐츠 생성 (텍스트, 이미지, TTS)

### 백엔드 아키텍처
- 계층형 아키텍처 4계층 + Facade 패턴 설계 (Controller → UseCase → Domain → Infra)
- 행위 기반 도메인 분리, UseCase Facade 패턴
- JSONL 기반 배치 파이프라인, Staging Table 패턴
- AOP 기반 비용 추적 (데코레이터 + EventEmitter)

### 대규모 실시간 처리
- 300명 이상 동시 접속 시험 시스템
- 실시간 데이터 생성 불안정성 해결 (사전 생성 방식)
- Data API 활용 워크로드 최적화

---

## 관련 문서

- [[문제생성엔진]] - AI 문제 생성 플랫폼 (NestJS)
- [[QGen AI]] - Python/FastAPI 마이그레이션
- [[RAG 시스템]] - Self-Refine RAG 시스템
- [[라스쿨]] - KB 협업 학습 관리 플랫폼
- [[똑스]] - 온라인 학습 플랫폼



# 이력서 - 백엔드 개발자 (AI/LLM)

## 기본 정보

**포지션**: Backend Developer (AI/LLM)
**경력**: 1년 3개월 (2024.11 ~ 현재)

---

## 자기소개

 _시스템과 AI를 활용해 유저 문제를 해결하는 백엔드 개발자입니다. 바로 코드로 뛰어들기보다 문제의 본질이 뭔지, 기술 없이도 풀 수 있는지 먼저 고민합니다. 맡은 영역에서 전문성을 쌓아가며, 동료들이 믿고 일할 수 있는 개발자가 되려고 합니다._
 시스템과 AI를 활용해 유저의 문제를 해결하는 백엔드 개발자 김노을입니다. 바로 개발에 착수하기보다 문제의 본질이 무엇인지, 정말 기술이 필요한 부분인지  먼저 고민합니다. 제가 맡은 영역에서 전문성을 쌓아가며, 동료들이 믿고 소통하며 함께 일할 수 있는 개발자가 되려고 합니다. 

---

## 기술 스택

### Backend
- **Language**: TypeScript, Python
- **Framework**: NestJS, FastAPI
- **ORM**: TypeORM, SQLAlchemy 2.0
- **Database**: PostgreSQL
- **Vector**:  PostgreSQL (pgvector)

### AI/LLM Experience
- **LLM**: Gemini, OpenAI, Claude
- **LLM Routing**: OpenRouter
- **Multimodal**: Gemini (이미지 생성, TTS)
- **Framework**: LangChain
- **AI Coding**: Claude Code, Cursor, Gemini CLI

### Infra
- **Cloud**: AWS EC2
- **Storage**: Supabase Storage, S3
- **Logging**: Winston, Morgan, Loguru, Slack Webhook
- **Validation**: Zod, Pydantic v2
- **Nocode**: Retool, Bubble
- **Container**: Docker, Nginx

---

## 프로젝트

### 1. QGen AI

NestJS 기반 LLM 통신부를 Python/FastAPI 4계층 클린 아키텍처로 마이그레이션하고, LangChain 기반 멀티 LLM 추상화 레이어를 설계했습니다.

**기간**: 2025.12 ~ 현재
**역할**: 백엔드 아키텍처 설계, API 구현
**기술**: Python, FastAPI, LangChain, SQLAlchemy 2.0, PostgreSQL

**문제 해결**:

1. **LLM 호출의 긴 응답 시간 문제**
   - API 호출 시 LLM 호출부에서 지연 발생, 후속 호출이 연속 발생하는 파이프라인 구조상 단일 API 요청 시간이 과도하게 길어짐
   - 요청 타임아웃 방지 및 단계별 실패 재시도를 위해 각 동작을 분리해야 함 → 이벤트 기반 아키텍처 도입
   - 단계별 API로 분리, 이벤트 기반 오케스트레이션으로 각 LLM 호출 독립 처리

2. **서비스 간 순환 참조 문제**
   - 서비스 간 직접 호출로 결합도 증가, 순환 참조 발생 위험
   - 비즈니스 흐름 조합은 별도 계층이 담당해야 함 → UseCase 레이어 도입
   - Facade 패턴으로 서비스 오케스트레이션, 서비스 간 직접 호출 제거

3. **배치 파이프라인 DB 동시성 문제**
   - 배치 생성용 프롬프트 빌드 단계에서 DB 조회/저장이 빈번하여 동시 요청 시 데이터 정합성 문제 발생
   - 동일 키워드에 대한 동시 요청 제어 필요 → Redis 분산 락 도입
   - 분산 락으로 배치 작업 순차 처리, 데이터 정합성 확보

4. **AI 에이전트 활용 가이드 부재**
   - 에이전트 기반 개발 환경에서 프로젝트 컨텍스트가 정의되지 않아 매번 컨텍스트를 전달해야 하는 상황
   - CLAUDE.md에 프로젝트 아키텍처 및 에이전트/커맨드 체계 정의
   - 코드 리뷰, PR 생성, 마이그레이션, 아키텍처 에이전트 등 개발 과정에 AI 워크플로우 적용

---

### 2. 문제생성엔진 (QGen)

국영수 교과목 문제를 관리하고 생성하는 교육 콘텐츠 시스템 백엔드를 구축했습니다. 수동 문제 관리, AI 문제 생성 파이프라인(실시간/대규모 배치), 멀티미디어 생성(이미지/TTS)을 설계하고 구현했습니다.

**기간**: 2025.07 ~ 2025.11
**역할**: 백엔드 아키텍처 설계, API 구현, 데이터베이스 설계, 데이터 구축, 프롬프트 개발
**기술**: NestJS, TypeScript, TypeORM, PostgreSQL, pgvector, Gemini/OpenAI/Claude API

**문제 해결**:

1. **LLM 인프라 결합도 문제**
   - 프로바이더마다 API 인터페이스가 달라 교체 시 코드 수정 범위가 큼
   - 교체가 빈번할 수 있어 추상화 필요 → Provider 패턴 선택
   - NestJS 토큰 기반 DI로 프로바이더 추상화, 토큰 교체만으로 구현체 교체 가능 

2. **다양한 문제 유형을 데이터로 표현해야 하는 문제**
   - 국영수 과목별로 객관식, 주관식, 듣기, 도표 등 다양한 유형 존재
   - 고정 스키마로는 과목/유형별 특수 요구사항 수용 불가 → JSON 컴포넌트 형식 선택
   - ComponentBlock 기반 JSONB 구조로 텍스트, 이미지, 테이블 등 자유롭게 조합 가능하도록 설계

3. **모의고사 데이터 구축 및 정합성 문제**
   - 원본 데이터를 JSON 컴포넌트 형식으로 변환하고 정합성 검증 필요
   - 수작업 검증은 누락 발생 → 스크립트 + AI 기반 이중 검사 체계 구축
   - 문제 번호, 정답, 배점 등 스크립트 검사 + 맞춤법, 형식 일관성 등 LLM 검사 자동화

4. **대규모 문항 생성 시 비용 문제**
   - 수백~수천 건 문항을 실시간 API로 생성하면 비용이 과다
   - Batch API 사용 시 50% 비용 절감 가능
   - 폴링 시스템 및 JSONL 빌드 → 제출 → 결과 다운로드 배치 파이프라인 구축

5. **LLM 생성 품질 측정 방법 부재**
   - 생성된 문제의 품질을 객관적으로 측정할 수 없음
   - 생성 프롬프트보다 검증 기준 정의 및 검증 프롬프트를 먼저 만들어야 품질 측정 가능
   - 검증 기준 설정 → 검증 프롬프트 개발 → 기준별 감별률 측정 → 생성 프롬프트 최적화

6. **과목별 AI 문제 생성 품질 차이**
   - 수학은 정답이 명확하고, 국어는 지문 맥락에 따라 다양한 문제가 필요
   - 과목별 특성에 맞는 생성 전략 필요
   - 수학은 temperature를 낮춰 논리적 정확성 확보, 국어는 temperature를 높여 맥락에 맞는 다양한 문제 생성

---

### 3. RAG 시스템

다양한 유형의 문제를 범용적으로 다루고 생성하기 위한 시스템입니다. 문제 생성, 임베딩, Self-Refine 시스템, 프롬프트 개발, 비용 측정 등을 구현했습니다.

**기간**: 2025.04 ~ 07
**역할**: 백엔드 API 개발, 데이터베이스 설계, 프롬프트 개발
**기술**: NestJS, TypeScript, PostgreSQL, pgvector, React, Retool

**문제 해결**:

1. **LLM 생성 문제의 품질 검증**
   - LLM이 생성한 문제가 레이아웃을 따르지 않거나 편향된 단어를 포함하는 등 품질이 일정하지 않음
   - 다양한 유형의 문제를 다루기 위해 범용적으로 적용 가능한 검증 기준 설정
   - AI를 통한 Self-Refine 패턴으로 기준별 평가 점수 기반 검증, 점수 미달 시 이유를 프롬프트에 주입해 최대 3회 재생성하여 품질 확보

2. **LLM 호출 비용 추적 문제**
   - 각 기능별 LLM 호출이 많아지면서 한 요청당 개별 비용 측정이 어려워짐
   - 모든 LLM 호출마다 비용 추적 코드를 넣으면 비즈니스 로직 결합도가 높아짐
   - 횡단 관심사 분리를 위해 AOP 형태 적용, `@CostTracking` 데코레이터 + EventEmitter 구현

3. **프롬프트 성능 측정 환경 부재**
   - 검증 프롬프트와 생성 프롬프트 개발 시 성능을 객관적으로 측정할 환경이 없음
   - 반복적인 프롬프트 개선을 위해 지표 기반 평가 환경 필요
   - Evaluation DB 구축 + Retool 대시보드에서 SQL 기반 지표 시각화, 데이터 기반 프롬프트 개발

---

### 4. KB 라스쿨

KB금융그룹과 협업하여 소외계층 학생 교육 지원 플랫폼을 구축했습니다. 온라인 진단시험 시스템, 인증/인가, 어드민, 학습 대시보드를 설계하고 구현했습니다.

**기간**: 2025.02 ~ 현재
**역할**: 백엔드 API 개발, 데이터베이스 설계
**기술**: Bubble Backend Workflow, Bubble Database, Data API

**문제 해결**:

1. **실시간 데이터 생성의 동시성 문제**
   - Bubble 플랫폼에서 데이터 생성 시간이 길고, 트랜잭션/락 구현이 불가능
   - 시험 시작 시 실시간으로 데이터를 생성하면 동시 접속 시 정합성 문제 발생
   - 시험 시작 전 예약 API를 통해 학생별 시험 데이터를 미리 생성, 시험 시작 시 상태 값만 업데이트

2. **Bubble 플랫폼 워크로드 비용 문제**
   - Bubble 플랫폼에서 워크로드 소모가 높아 비용 관리 필요
   - 공식 문서에서 Data API 발견, 벌크 데이터 처리 가능 확인
   - Data API 적용으로 한 번에 대량 데이터 생성, 워크로드 비용 절감

---

### 5. 똑스

온라인 학습 플랫폼의 백엔드를 구축했습니다. 모의고사 시스템(API, DB, 채점), AI 학습 도구, 유저 학습 로그 기능을 구현하고, 순환 참조 구조의 학습 자료 데이터베이스를 마이그레이션했습니다.

**기간**: 2024.11 ~ 현재
**역할**: 백엔드 API 개발, 데이터베이스 구축
**기술**: Bubble Backend Workflow, Bubble Database, Gemini/OpenAI API

**문제 해결**:

1. **학습 자료 데이터베이스 구조 복잡성 문제**
   - 유저 학습 로그 기능 개발 필요했으나 DB 구조가 복잡하게 얽혀있어 파악 불가
   - ERD 추출하여 구조 분석 및 재설계
   - 마이그레이션 스크립트 작성하여 데이터 정리, 학습 로그 기능 개발

2. **레거시 API 중단 문제**
   - 기존 사용 중인 API가 갑자기 동작 중단, deprecated API 사용 중이었음
   - API Connector를 하나로 묶어 체계화, Failover 구조 설계
   - 대체 API 연결 및 버전 업그레이드로 안정성 확보

---

## 경력

### 큐레아 | Backend Developer
**2024.11 ~ 현재** (1년 3개월)

AI 기반 교육 콘텐츠 생성 시스템 및 온라인 학습 플랫폼의 백엔드 시스템을 설계하고 구현했습니다.

---

## 학력

### 한양사이버대학교 | 응용소프트웨어공학과
**2025.03 ~ 현재** (3학년 재학 중)

---

## 교육

### 스파르타코딩클럽 | Node.js 백엔드 개발자 양성 과정
**2024.04 ~ 2024.08**

---

## 관련 문서

- [[문제생성엔진]] - AI 문제 생성 플랫폼 (NestJS)
- [[QGen AI]] - Python/FastAPI 마이그레이션
- [[RAG 시스템]] - Self-Refine RAG 시스템
- [[라스쿨]] - KB 협업 학습 관리 플랫폼
- [[똑스]] - 온라인 학습 플랫폼

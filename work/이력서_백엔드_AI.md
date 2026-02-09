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
- 여러 Service를 조합하는 복잡한 비즈니스 흐름에서 의존성 관리 어려움
  → UseCase에 Facade 패턴 적용, Controller는 UseCase 하나만 호출
- NestJS(TypeORM)와 Python(SQLAlchemy)이 동일 DB를 공유해야 하는 상황
  → sqlacodegen으로 기존 스키마에서 모델 자동 생성, 스키마 변경 없이 공존

**담당 기능**:
- 클린 아키텍처 / 헥사고날 아키텍처 4계층 설계 (Controller → UseCase → Service → Provider)
- 행위 기반 도메인 분리 (생성/배치/미디어/QC/임베딩)
- DI 패턴 설계 (Provider 싱글톤 + Service 요청별 팩토리)
- Claude Code 기반 AI 개발 워크플로우 구축 (에이전트 6종, 커맨드 9종)

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
- 클린 아키텍처 / 헥사고날 아키텍처 4계층 설계 (Controller → UseCase → Service → Provider)
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

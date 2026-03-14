---
paths: ["knowledge/**"]
---

# knowledge 영역 규칙

## 다루는 주제

| 영역 | 주요 주제 |
|------|-----------|
| AI/데이터 | LLM, RAG, 임베딩, 벡터 DB, 프롬프트 엔지니어링, MLOps |
| 인프라/클라우드 | Docker, Kubernetes, AWS/GCP/Azure, CI/CD, IaC |
| 백엔드 개발 | API 설계, 데이터베이스, 인증/보안, 마이크로서비스 |
| 프론트엔드 | React, TypeScript, 상태관리, 성능 최적화 |

## 문서 유형별 섹션 구조

### 개념 문서 (concepts/)

1. 정의 — 한 문장 요약 후 상세 설명
2. 등장 배경 및 필요성
3. 작동 원리 / 핵심 개념
4. 장점 및 이점
5. 한계점 및 고려사항
6. 실무 적용 가이드 (선택)
7. 관련 문서

### 튜토리얼 문서 (tutorials/)

1. 개요 — 무엇을 배우는가, 예상 소요 시간
2. 사전 준비
3. 단계별 진행
4. 결과 확인
5. 트러블슈팅
6. 관련 문서

### 문제 해결 기록 (troubleshooting/)

1. 문제 상황
2. 원인 분석
3. 해결 방법
4. 예방 방법 (선택)

## 태그 체계

- **유형**: concept, tutorial, troubleshooting, reference
- **주제**: ai, llm, rag, embedding, mlops, devops, docker, k8s, cloud, cicd, backend, frontend, database, api, security, tools, terminal
- **상태**: draft, review, done

## 작성 스타일

- 핵심 정보가 누락되지 않되, 불필요하게 장황한 설명은 피합니다.
- 긴 설명 시 문단 구분 또는 글머리 기호를 활용합니다.
- 한 섹션이 지나치게 길면 하위 섹션으로 분리합니다.
- 추측/모호 표현을 피합니다. "~일 수 있습니다", "~인 것 같습니다"를 최소화합니다.

## 품질 체크리스트

- 프론트매터가 올바른 형식인지 확인합니다.
- 문서 유형에 맞는 섹션 구조를 따릅니다.
- 비전문가도 이해할 수 있는 수준으로 설명합니다.
- 실무 관점의 장단점/고려사항을 포함합니다.
- 관련 문서 링크를 적절히 연결합니다.

## 지양 사항

- 추측성 표현
- 과도한 영문 병기
- 근거 없는 주장
- 지나치게 짧거나 긴 설명

## 작업 전 필수 확인

- 새 문서 작성 시 `knowledge/_templates/CONCEPT.md` 템플릿을 기반으로 합니다.
- 새 문서 작성 전 반드시 `knowledge/_meta/INDEX.md`를 읽어 중복을 방지합니다.
- 새 용어 작성 시 `knowledge/_meta/GLOSSARY.md`를 확인합니다.

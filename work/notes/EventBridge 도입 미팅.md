---
created: 2026-02-02
updated: 2026-02-02
tags: [note, meeting, devops, cloud]
status: draft
---

# EventBridge 도입 미팅

> 배치 처리 스케줄링에 EventBridge를 도입하는 것이 적절한지 검토하기 위한 미팅 어젠다입니다.

---

## 1. 요약

배치 처리 스케줄링을 애플리케이션 내부가 아닌 AWS EventBridge로 분리하는 것이 적절한지 검토합니다.

---

## 2. 상세 내용

### 2.1 현재 상황

- 배치 제출/폴링 스케줄링이 애플리케이션 내부에서 관리되고 있음
- 스케줄 변경 시 코드 수정 및 배포가 필요
- 스케줄러 on/off를 위해 배포 또는 DB 설정 변경이 필요

### 2.2 EventBridge 도입 시 장점

- 스케줄 변경이 Rule 수정만으로 가능 (코드 배포 불필요)
- Rule enable/disable로 스케줄러 즉시 on/off 제어
- CloudWatch 메트릭/로그와 자연스러운 통합
- 애플리케이션에서 스케줄링 책임 분리 (관심사 분리)

### 2.3 우려 사항 / 트레이드오프

- EventBridge → API Gateway → LLM Service 호출 경로가 길어짐 (타임아웃 관리 포인트 증가)
- 장애 시 재시도 정책을 인프라 레벨에서 별도 설정해야 함
- 기존 스케줄러 코드 제거 및 마이그레이션 과도기 관리

### 2.4 논의 필요 사항

- 현재 구조 대비 EventBridge로 전환할 만큼의 실익이 있는가
- 호출 경로 복잡도 증가가 수용 가능한 수준인가
- 마이그레이션 전략 (점진적 전환 vs 일괄 전환)

---

## 3. 액션 아이템

- [ ] 도입 여부 최종 결정
- [ ] 결정 시 EventBridge Rule + API Gateway 연동 PoC 진행

---

## 관련 문서

- [[Batch Processing]] - 배치 처리 전체 아키텍처 및 시퀀스 다이어그램

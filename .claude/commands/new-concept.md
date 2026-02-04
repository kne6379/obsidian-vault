---
description: 새 개념 문서 작성 + 검수 + 등록 + 푸시
---

새 개념 문서 "$ARGUMENTS"를 작성하고 전체 등록 플로우를 실행합니다.

## 실행 순서

1. **문서 작성**
   - develop/concepts/$ARGUMENTS.md 생성
   - _templates/CONCEPT.md 템플릿 기반
   - 웹 검색으로 내용 조사 후 작성

2. **품질 검수**
   - 프론트매터 확인 (created, updated, tags, status)
   - 문체 검수 (~입니다/~합니다 체)
   - 필수 섹션 확인
   - 링크 유효성 확인

3. **인덱스 업데이트**
   - develop/_meta/INDEX.md에 문서 추가
   - 통계 업데이트
   - 최근 업데이트 섹션 추가

4. **용어집 업데이트**
   - 새 용어가 있으면 develop/_meta/GLOSSARY.md에 추가

5. **관련 문서 링크**
   - 기존 관련 문서에 상호 링크 추가

6. **Git 커밋 & 푸시**
   - 변경사항 커밋
   - origin에 푸시

## 주의사항

- 검수 실패 시 수정 후 재검수
- 모든 단계 완료 후에만 푸시

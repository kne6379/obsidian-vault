# CLAUDE.md 아키텍처 리팩토링 구현 계획

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 볼트의 CLAUDE.md 구조를 `.claude/rules/` 기반 정밀 컨텍스트 주입 아키텍처로 전환한다.

**Architecture:** 루트 CLAUDE.md는 에이전트 정체성(~20줄)만 담고, 모든 작성 규칙은 `.claude/rules/`로 이동한다. 공통 규칙은 `common.md`(항상 로드), 영역별 규칙은 `paths` 프론트매터로 조건부 로드한다.

**Tech Stack:** Obsidian Vault, Claude Code `.claude/rules/`, Markdown

**Spec:** `docs/superpowers/specs/2026-03-14-claude-md-architecture-refactor-design.md`

---

## Chunk 1: `.claude/rules/` 파일 생성

새 규칙 소스를 먼저 확보한다. 기존 파일은 아직 건드리지 않는다.

### Task 1: common.md 생성

**Files:**
- Create: `.claude/rules/common.md`
- Reference: `CLAUDE.md` (현재 루트 — 공통 규칙 원본)

- [ ] **Step 1: common.md 작성**

```markdown
# 공통 작성 규칙

## 문체

- "~니다" 체의 공식 문어체를 사용한다.
- 구어체, 반말, 이모지는 사용하지 않는다.

## 용어

- 한글 우선 원칙: 의미 전달에 불필요한 영어 단어의 괄호 병기는 지양한다.
- 영문 병기 기준: 최초 등장 시 개념 정의가 필요한 경우에만 한글(English) 형식으로 병기한다.
- 이후 동일 문서 내에서는 한글만 사용한다.

## 프론트매터

모든 문서 최상단에 포함한다:

---
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [태그1, 태그2]
status: (영역별 상태값 참조)
---

## 링크

- 다른 문서에서 정의된 개념은 [[문서명]] 형식으로 링크한다.
- 특정 섹션: [[문서명#섹션명]]
- 별칭: [[문서명|표시할 텍스트]]
- 모든 문서 하단에 ## 관련 문서 섹션을 추가한다.
- 외부 참고 자료는 ## 참고 자료 섹션에 정리한다.

## 품질

- 사내 보고서 또는 실무 공유 문서에 바로 사용할 수 있는 수준으로 작성한다.
- 추측이나 모호한 표현은 피하고, 정의/구분/비교가 필요한 경우 명확히 구분한다.

## 영역 인식

- 작업 대상 영역이 명확하면 해당 영역의 파일을 먼저 읽거나 편집하여 영역별 규칙이 자동 로드되도록 한다.
```

- [ ] **Step 2: 커밋**

```bash
git add .claude/rules/common.md
git commit -m "Add common.md rules file for shared writing conventions"
```

### Task 2: develop.md 생성

**Files:**
- Create: `.claude/rules/develop.md`
- Reference: `develop/_meta/RULES.md` (원본)
- Reference: `develop/CLAUDE.md` (영역 소개 원본)

- [ ] **Step 1: develop.md 작성**

`develop/_meta/RULES.md`에서 내용을 가져오되, common.md와 중복되는 문체/용어/링크 규칙은 제거하고, 커맨드 파일이 담당하는 워크플로우도 제거한다. `develop/CLAUDE.md`의 영역 소개 테이블을 상단에 통합한다.

```yaml
---
paths: ["develop/**"]
---
```

포함할 내용:
- 영역 소개 테이블 (AI/데이터, 인프라/클라우드, 백엔드, 프론트엔드)
- 문서 유형별 섹션 구조:
  - 개념 문서: 정의 → 등장 배경 → 작동 원리 → 장점 → 한계점 → 실무 적용(선택) → 관련 문서
  - 튜토리얼: 개요 → 사전 준비 → 단계별 진행 → 결과 확인 → 트러블슈팅 → 관련 문서
  - 문제 해결: 문제 상황 → 원인 분석 → 해결 방법 → 예방 방법(선택)
- 태그 체계 (유형 + 주제 + 상태)
- 작성 스타일 세부 (분량/구조, 명확성)
- 품질 기준 체크리스트 + 지양 사항
- 지시: 새 문서 작성 시 `develop/_templates/CONCEPT.md` 템플릿 기반
- 지시: 새 문서 작성 전 `develop/_meta/INDEX.md`를 읽어 중복 방지
- 지시: 새 용어 작성 시 `develop/_meta/GLOSSARY.md` 확인

- [ ] **Step 2: 커밋**

```bash
git add .claude/rules/develop.md
git commit -m "Add develop.md rules file for development area conventions"
```

### Task 3: work.md 생성

**Files:**
- Create: `.claude/rules/work.md`
- Reference: `work/_meta/RULES.md` (원본)

- [ ] **Step 1: work.md 작성**

`work/_meta/RULES.md`에서 내용을 가져오되, common.md 중복 제거. 워크플로우 제거.

```yaml
---
paths: ["work/**"]
---
```

포함할 내용:
- 문서 유형별 섹션 구조:
  - 프로젝트: 개요 → 기술 스택 → 아키텍처 → 주요 기능 → 이슈 및 회고(선택) → 관련 문서
  - 기술 의사결정: 배경 → 검토 대안 → 최종 결정 → 관련 문서
  - 노트: 요약 → 상세 내용 → 액션 아이템(선택) → 관련 문서
  - 문제 해결: 문제 상황 → 원인 분석 → 해결 방법 → 예방 방법(선택)
- 상태값 (draft, active, completed, archived)
- 태그 체계 (유형 + 노트 세부 + 상태)
- 지시: 새 문서 작성 전 `work/_meta/INDEX.md`를 읽어 중복 방지

- [ ] **Step 2: 커밋**

```bash
git add .claude/rules/work.md
git commit -m "Add work.md rules file for work area conventions"
```

### Task 4: life.md 생성

**Files:**
- Create: `.claude/rules/life.md`
- Reference: `life/_meta/RULES.md` (원본)

- [ ] **Step 1: life.md 작성**

```yaml
---
paths: ["life/**"]
---
```

포함할 내용:
- 문서 유형 (생각/가치관, 의사결정, 회고)
- 상태값 (draft, done)
- 지시: 새 문서 작성 전 `life/_meta/INDEX.md`를 읽어 중복 방지
- 지시: 새 용어 작성 시 `life/_meta/GLOSSARY.md` 확인

- [ ] **Step 2: 커밋**

```bash
git add .claude/rules/life.md
git commit -m "Add life.md rules file for life area conventions"
```

### Task 5: business.md 생성

**Files:**
- Create: `.claude/rules/business.md`
- Reference: `business/_meta/RULES.md` (원본)
- Reference: `business/CLAUDE.md` (영역 소개 원본)

- [ ] **Step 1: business.md 작성**

`business/_meta/RULES.md`에서 내용을 가져오되, common.md 중복 제거. `business/CLAUDE.md`의 영역 소개를 상단에 통합.

```yaml
---
paths: ["business/**"]
---
```

포함할 내용:
- 영역 소개 (브레인스토밍, 사업 기획, 실행 계획)
- 문서 유형별 섹션 구조:
  - 브레인스토밍: 주제 정의 → 시장 조사 → 아이디어 목록 → 평가 → 추천 및 다음 단계 → 관련 문서 → 참고 자료
- 메타데이터 (domain 필드 포함)
- 상태값 (idea, exploring, validated, archived)
- 아이디어 평가 기준 (실현 가능성/시장성/차별성 5점 척도)
- 태그 체계
- 작성 스타일 세부 (데이터 기반, 구체성)
- 영역 간 링크 규칙 (develop/, work/ 적극 연결)
- 지시: 새 문서 작성 시 `business/_templates/BRAINSTORM.md` 템플릿 기반
- 지시: 새 문서 작성 전 `business/_meta/INDEX.md`를 읽어 중복 방지
- 지시: 새 용어 작성 시 `business/_meta/GLOSSARY.md` 확인

- [ ] **Step 2: 커밋**

```bash
git add .claude/rules/business.md
git commit -m "Add business.md rules file for business area conventions"
```

---

## Chunk 2: 루트 CLAUDE.md 재작성 + 기존 파일 정리

새 규칙 소스가 확보된 상태에서, 루트를 재작성하고 기존 파일을 삭제한다.

### Task 6: 루트 CLAUDE.md 재작성

**Files:**
- Modify: `CLAUDE.md` (162줄 → ~20줄)

- [ ] **Step 1: CLAUDE.md 전체 재작성**

기존 내용을 모두 교체한다. spec에 정의된 내용 그대로:

```markdown
# 에이전트 지침

## 볼트의 본질

이 볼트는 "나는 누구인가"를 탐구하고 기록하며 성장해가는 공간이다.
개념 간 [[링크]]로 연결된 그래프를 통해 삶을 다각적으로 바라본다.

## 페르소나

IMPORTANT: 조언이나 피드백을 줄 때는 형처럼 직설적으로 한다.
- 반말 사용
- 핵심만 말함
- 필요하면 쓴소리도 함
- 둘러 말하지 않음
- 단, 문서를 작성할 때는 공통 규칙(~니다 체)을 따른다.

## 볼트 구조

| 영역 | 목적 | 공개 |
|------|------|------|
| develop/ | 개발 지식 | 공개 |
| work/ | 회사 프로젝트 | 공개 |
| life/ | 생각, 가치관, 삶 | 비공개 |
| business/ | AI 사업 기획 | 비공개 |

각 영역은 _meta/ (INDEX, GLOSSARY), _templates/ 구조를 가진다.
```

- [ ] **Step 2: 커밋**

```bash
git add CLAUDE.md
git commit -m "Rewrite root CLAUDE.md to minimal agent identity (~20 lines)"
```

### Task 7: 하위 CLAUDE.md 삭제

**Files:**
- Delete: `develop/CLAUDE.md`
- Delete: `business/CLAUDE.md`

- [ ] **Step 1: develop/CLAUDE.md 삭제**

```bash
rm "develop/CLAUDE.md"
```

- [ ] **Step 2: business/CLAUDE.md 삭제**

```bash
rm "business/CLAUDE.md"
```

- [ ] **Step 3: 커밋**

```bash
git add "develop/CLAUDE.md" "business/CLAUDE.md"
git commit -m "Remove subdirectory CLAUDE.md files (replaced by .claude/rules/)"
```

### Task 8: _meta/RULES.md 삭제

**Files:**
- Delete: `develop/_meta/RULES.md`
- Delete: `work/_meta/RULES.md`
- Delete: `life/_meta/RULES.md`
- Delete: `business/_meta/RULES.md`

- [ ] **Step 1: 4개 RULES.md 삭제**

```bash
rm "develop/_meta/RULES.md"
rm "work/_meta/RULES.md"
rm "life/_meta/RULES.md"
rm "business/_meta/RULES.md"
```

- [ ] **Step 2: 커밋**

```bash
git add "develop/_meta/RULES.md" "work/_meta/RULES.md" "life/_meta/RULES.md" "business/_meta/RULES.md"
git commit -m "Remove _meta/RULES.md files (migrated to .claude/rules/)"
```

### Task 9: 검증

- [ ] **Step 1: 파일 구조 확인**

```bash
ls -la .claude/rules/
cat CLAUDE.md
```

`.claude/rules/`에 5개 파일(common, develop, work, life, business)이 존재하고, 루트 CLAUDE.md가 ~20줄인지 확인한다.

- [ ] **Step 2: 삭제된 파일 확인**

```bash
ls develop/CLAUDE.md 2>&1
ls business/CLAUDE.md 2>&1
ls develop/_meta/RULES.md 2>&1
ls work/_meta/RULES.md 2>&1
ls life/_meta/RULES.md 2>&1
ls business/_meta/RULES.md 2>&1
```

모두 "No such file or directory"가 나와야 한다.

- [ ] **Step 3: 유지된 파일 확인**

```bash
ls develop/_meta/INDEX.md
ls develop/_meta/GLOSSARY.md
ls work/_meta/INDEX.md
ls life/_meta/INDEX.md
ls life/_meta/GLOSSARY.md
ls business/_meta/INDEX.md
ls business/_meta/GLOSSARY.md
```

모두 존재해야 한다.

- [ ] **Step 4: git status 확인**

```bash
git status
```

clean 상태 확인 (untracked 파일 제외).

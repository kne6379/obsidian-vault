---
created: 2026-03-13
updated: 2026-03-22
tags: [concept, ai, devops]
status: done
---

# CLAUDE.md 설계 원칙

> Claude Code가 프로젝트 규칙을 정확히 인식하고 일관되게 적용하도록 CLAUDE.md 파일을 설계하는 원칙과 구조를 정의합니다.

---

## 1. 정의

CLAUDE.md는 Claude Code(Anthropic의 CLI 도구)가 세션 시작 시 읽어들이는 **지시 컨텍스트 파일**입니다. 프로젝트의 코딩 표준, 아키텍처 규칙, 빌드 명령어 등을 담아 Claude가 모든 세션에서 동일한 기준으로 작업하도록 합니다.

중요한 점은 CLAUDE.md가 사람을 위한 문서가 아니라 **AI를 위한 지시사항**이라는 것입니다. 사람에게 좋은 문서 구조와 AI에게 효과적인 지시 구조는 근본적으로 다릅니다.

---

## 2. 등장 배경 및 필요성

[[AI 네이티브 엔지니어]]가 여러 AI 에이전트를 운용하면서, 에이전트가 코드베이스의 규칙을 일관되게 따르도록 하는 것이 핵심 과제가 되었습니다.

- **세션 간 일관성 부재**: Claude Code는 매 세션마다 새로운 컨텍스트 윈도우로 시작합니다. 명시적 지시가 없으면 에이전트는 자체 학습 데이터 기반으로 코드를 생성하며, 동일 프로젝트에서 세션마다 다른 패턴의 코드가 나올 수 있습니다.
- **에이전트 친화적 환경 필요**: 에이전트가 "스스로 판단해서 컨벤션을 찾아 읽는" 구조는 신뢰할 수 없습니다. 규칙을 자동으로 주입하는 메커니즘이 필요합니다.
- **컨텍스트 윈도우 제약**: 모든 지시를 한 파일에 넣으면 토큰을 과도하게 소비하고, 너무 분산시키면 규칙이 로드되지 않습니다. 효율적인 구조 설계가 필요합니다.

---

## 3. 작동 원리 / 핵심 개념

### 3.1 로딩 메커니즘

CLAUDE.md 파일의 위치와 참조 방식에 따라 로딩 동작이 달라집니다.

| 위치/방식 | 로딩 시점 | Compaction 생존 |
|-----------|-----------|----------------|
| 루트 CLAUDE.md | 세션 시작 시 전체 로드 | 생존 (디스크에서 재주입) |
| 상위 디렉토리 CLAUDE.md | 세션 시작 시 전체 로드 | 생존 |
| 하위 디렉토리 CLAUDE.md | 해당 디렉토리 파일을 읽을 때 온디맨드 로드 | 비생존 |
| `@path` import | 세션 시작 시 참조 파일까지 함께 로드 (최대 5단계) | 생존 |
| 마크다운 링크 `[](path)` | **자동 로드되지 않음**. Claude가 스스로 읽기로 결정해야 함 | 비생존 |
| `.claude/rules/*.md` | `paths` 없으면 세션 시작 시, 있으면 매칭 파일 작업 시 | 조건부 |

핵심 구분은 **`@import`와 마크다운 링크의 차이**입니다. `@path/to/file`은 CLAUDE.md 로드 시 해당 파일 내용을 함께 확장하여 컨텍스트에 주입합니다. 반면 `[텍스트](path/to/file)` 형식의 마크다운 링크는 단순한 텍스트일 뿐, Claude Code가 자동으로 따라가지 않습니다.

### 3.2 Compaction 동작

긴 작업 중 컨텍스트 윈도우가 가득 차면 Compaction이 발생합니다.

- **CLAUDE.md 내용**: 디스크에서 다시 읽어 재주입됩니다. Compaction을 100% 생존하는 유일한 메커니즘입니다.
- **`@import`로 확장된 내용**: CLAUDE.md와 함께 재주입됩니다.
- **대화 중 Read로 읽은 문서 내용**: 사라집니다.
- **마크다운 링크로 연결된 문서**: 대화 중 읽었더라도 사라집니다.

### 3.3 계층 구조와 우선순위

CLAUDE.md는 여러 위치에 존재할 수 있으며, 더 구체적인 위치가 우선합니다.

| 범위 | 위치 | 용도 |
|------|------|------|
| 관리 정책 | `/Library/Application Support/ClaudeCode/CLAUDE.md` (macOS) | 조직 전체 표준 |
| 프로젝트 | `./CLAUDE.md` 또는 `./.claude/CLAUDE.md` | 팀 공유 규칙 |
| 사용자 | `~/.claude/CLAUDE.md` | 개인 환경 설정 |

### 3.4 `.claude/rules/` 디렉토리

대규모 프로젝트에서는 규칙을 주제별 파일로 분리하여 `.claude/rules/`에 배치합니다.

```
.claude/rules/
├── api-conventions.md      # paths: "src/**/*.controller.ts"
├── testing-standards.md    # paths: "**/*.spec.ts"
└── entity-conventions.md   # paths: "src/**/*.entity.ts"
```

`paths` 프론트매터가 있는 규칙은 해당 패턴에 매칭되는 파일을 작업할 때만 로드되어 컨텍스트를 절약합니다.

---

## 4. 장점 및 이점

올바른 CLAUDE.md 아키텍처를 적용하면 다음과 같은 효과를 얻습니다.

- **세션 간 일관성 보장**: 어떤 세션에서든 동일한 코딩 표준이 자동 적용됩니다. 에이전트의 자율적 판단에 의존하지 않으므로 결과물의 편차가 줄어듭니다.
- **Compaction 내성**: 핵심 규칙이 `@import`로 CLAUDE.md에 연결되어 있으므로, 긴 작업 중 Compaction이 발생해도 규칙이 유실되지 않습니다.
- **컨텍스트 효율성**: 모든 규칙을 무조건 로드하는 대신, 작업 중인 파일 유형에 따라 관련 규칙만 로드하여 토큰 소비를 줄입니다.
- **턴/토큰 절약**: 에이전트가 매번 "어떤 규칙 문서를 읽어야 하는가"를 탐색하는 과정이 사라집니다. 10개 파일 수정 작업에서 이 탐색 과정만으로 소비되던 턴이 절약됩니다.

---

## 5. 한계점 및 고려사항

### 5.1 잘못된 아키텍처의 구체적 문제점

CLAUDE.md를 문서 인덱스처럼 설계하면(마크다운 링크로 외부 문서를 나열하는 방식) 다음 문제가 발생합니다.

**규칙 미인식**

마크다운 링크 `[컨벤션](docs/convention.md)`는 `@import`가 아닙니다. Claude Code는 이 링크를 자동으로 따라가지 않습니다. 세션 시작 시 CLAUDE.md를 읽으면 문서 링크 목록만 보이고, 실제 규칙은 하나도 인식하지 못합니다.

```
세션 시작 → CLAUDE.md 로드 → 마크다운 링크 20개만 인식
                             → 실제 규칙은 0개 인식
```

**세션 간 일관성 붕괴**

Claude가 스스로 "이 작업에 필요한 문서를 읽어야겠다"고 판단해야 하는 구조에서는, 읽을 때는 컨벤션을 따르고 안 읽을 때는 자체 학습 데이터 기반으로 코드를 작성합니다. 동일 프로젝트에서 세션마다 다른 패턴의 코드가 생산됩니다.

| 상황 | 문서를 읽었을 때 | 문서를 안 읽었을 때 |
|------|----------------|-------------------|
| 응답 래핑 | `SuccessResponse.of(data)` 사용 | 직접 `{ success: true, data }` 리턴 |
| 에러 처리 | `BusinessException` + `ErrorMessages` | 프레임워크 기본 예외 throw |
| 패턴 적용 | 커스텀 인터페이스 통해 접근 | 기본 패턴 직접 사용 |

**Compaction 후 규칙 망각**

작업 초반에 외부 문서를 Read로 읽고 올바르게 코드를 작성하다가, Compaction 이후에는 그 규칙을 잊어버리고 다른 패턴으로 작성할 수 있습니다. CLAUDE.md 본문과 `@import` 내용만이 Compaction을 생존합니다.

**컨텍스트 윈도우 낭비**

에이전트가 매번 다음 과정을 반복합니다.

1. CLAUDE.md를 다시 읽음 (어떤 문서가 있는지 확인)
2. 관련 문서 경로를 파악
3. 해당 문서를 Read로 열음
4. 내용을 파악하고 적용

이 탐색 과정이 매번 1~2턴을 소모하며, 상당한 토큰이 낭비됩니다.

**우선순위 불명확**

모든 외부 문서가 동등한 테이블 행으로 나열되면, 아키텍처 레이어 의존 방향(위반 시 치명적)과 데코레이터 패턴(위반 시 경미)의 구분이 사라집니다.

**전체 무시 가능성**

Claude Code 시스템 프롬프트에는 "this context may or may not be relevant to your tasks"라는 문구가 포함됩니다. 직접적인 지시("MUST", "항상") 없이 링크만 있으면, Claude가 전체 CLAUDE.md를 현재 작업과 무관하다고 판단하고 무시할 가능성이 있습니다.

### 5.2 문제 심각도 요약

| 문제 | 원인 | 심각도 |
|------|------|--------|
| 규칙 미인식 | 마크다운 링크 ≠ `@import` | 높음 |
| 세션 간 일관성 붕괴 | Claude의 자율적 문서 탐색에 의존 | 높음 |
| Compaction 후 규칙 망각 | 외부 문서 내용은 Compaction 비생존 | 높음 |
| 턴/토큰 낭비 | 매번 다단계 문서 탐색 필요 | 중간 |
| 우선순위 불명확 | 모든 문서가 동일 가중치로 나열 | 중간 |
| 전체 무시 가능성 | 직접 지시 없이 링크만 존재 | 중간 |

### 5.3 올바른 설계에서의 고려사항

- **200줄 제한**: 공식 권장사항은 CLAUDE.md 파일당 200줄 이하입니다. 길수록 준수율이 하락합니다.
- **`@import`의 텍스트 치환 특성**: `@import`는 마크다운 구조를 자동 조정하지 않습니다. 가져올 파일의 헤딩 레벨을 사전에 맞춰야 합니다.
- **강조 표현의 효과**: "IMPORTANT", "MUST", "NEVER" 같은 강조 표현이 준수율을 높이지만, 남용하면 효과가 감소합니다.

---

## 6. 실무 적용 가이드

### 6.1 의사결정 트리: 규칙의 적합한 위치

| 규칙의 성격 | 적합한 위치 |
|------------|------------|
| 모든 작업에 항상 적용 | CLAUDE.md 인라인 |
| 특정 파일/디렉토리 작업 시만 | `.claude/rules/` + `paths` 프론트매터 |
| 특정 워크플로우에서만 | `.claude/skills/` |
| 포맷팅/린팅 같은 결정론적 규칙 | Hooks (CLAUDE.md가 아닌 스크립트) |

### 6.2 CLAUDE.md에 인라인해야 할 것

다음 항목은 Claude가 코드를 읽어도 추측할 수 없으므로 CLAUDE.md 본문에 직접 작성해야 합니다.

- **빌드/테스트 명령어**: `npm run build`, `pytest -x` 등
- **아키텍처 의존 방향**: Controller → Service → Repository 같은 레이어 규칙
- **네이밍 규칙**: 파일명 suffix, 케이스 규칙
- **에러 처리 패턴**: 커스텀 예외 클래스, 에러 코드 체계
- **비직관적 동작**: 환경변수 quirks, 특수 설정

### 6.3 CLAUDE.md에서 제외해야 할 것

- Claude가 코드를 읽으면 알 수 있는 것
- "깨끗한 코드를 작성하라" 같은 자명한 지시
- 세부 데코레이터 패턴 → `.claude/rules/`로 이동
- 테스트 작성 상세 규칙 → `.claude/rules/`로 이동
- 코드 스타일 포맷팅 → Hooks + ESLint/Prettier로 처리

### 6.4 효과적인 지시 작성법

**구체적이고 검증 가능한 지시를 작성합니다.**

| 나쁜 예 | 좋은 예 |
|---------|---------|
| "코드를 적절히 포맷하라" | "2-space indentation을 사용한다" |
| "테스트를 작성하라" | "커밋 전 `npm test`를 실행한다" |
| "파일을 정리하라" | "API 핸들러는 `src/api/handlers/`에 위치한다" |

**강조가 필요한 규칙에는 명시적 표현을 사용합니다.**

```markdown
IMPORTANT: 모든 API 응답은 반드시 SuccessResponse.of()로 래핑한다.
NEVER: Service 레이어에서 직접 HTTP 예외를 throw하지 않는다.
```

### 6.5 성숙도 레벨

커뮤니티에서 수렴된 CLAUDE.md 성숙도 프레임워크입니다.

| 레벨 | 설명 |
|------|------|
| L0 | CLAUDE.md 없음 |
| L1 | 파일 존재, git 추적 |
| L2 | "MUST" 같은 명시적 지시 사용 |
| L3 | 여러 파일로 분리, 라우터 역할 |
| L4 | 경로 기반 조건부 규칙 로딩 (`.claude/rules/` + `paths`) |
| L5 | 지속적 유지보수, 정기 리뷰 |

L4 이상이 되어야 대규모 프로젝트에서 안정적으로 동작합니다.

### 6.6 실전 사례: Unlook 프로젝트

Unlook은 FastAPI + Flutter 기반 데이팅 플랫폼으로, Hexagonal Architecture + Tactical DDD를 채택한 프로젝트입니다. 이 프로젝트의 `.claude/` 구성은 본 문서에서 다룬 원칙들이 실무에서 어떻게 적용되는지 보여주는 사례입니다.

#### 전체 파일 구조

```
CLAUDE.md                          ← 루트: 스택, 구조, 커밋 컨벤션
api/CLAUDE.md                      ← 백엔드: 아키텍처, 의존성 방향, 핵심 패턴, 네이밍
.claude/
├── rules/backend/
│   ├── architecture.md            ← 계층 구조, DI, 에러 처리
│   ├── domain.md                  ← 순수 비즈니스 로직 규칙
│   ├── application.md             ← Use Case, Facade, Compensation
│   ├── infrastructure.md          ← Repository, Adapter, ORM
│   ├── presentation.md            ← Router, 예외 핸들러
│   ├── testing.md                 ← TDD, 4단계 테스트, Mock 전략
│   └── ml-pipeline.md             ← GPU 추론, 벡터 처리
├── skills/
│   ├── architecture/SKILL.md      ← 아키텍처 가이드 자동 적용
│   ├── test-conventions/SKILL.md  ← TDD 워크플로우 자동 적용
│   ├── review/SKILL.md            ← Gemini+Claude 2단 코드 리뷰
│   ├── test/SKILL.md              ← 테스트 실행 + 분석 오케스트레이터
│   ├── domain-docs/SKILL.md       ← 도메인 문서 동기화
│   ├── commit/SKILL.md            ← 커밋 메시지 생성
│   ├── pr/SKILL.md                ← PR 생성
│   ├── issue/SKILL.md             ← 이슈 생성
│   └── document/SKILL.md          ← 코드 문서화
└── agents/
    ├── api-reviewer.md            ← 백엔드 코드 리뷰 전문 에이전트
    ├── app-reviewer.md            ← 프론트엔드 코드 리뷰 전문 에이전트
    ├── api-test-runner.md         ← 백엔드 테스트 실행 전문 에이전트
    ├── app-test-runner.md         ← 프론트엔드 테스트 실행 전문 에이전트
    └── security-auditor.md        ← 보안 감사 전문 에이전트
```

#### CLAUDE.md 2단계 구조: 루트와 하위 디렉토리

루트 `CLAUDE.md`는 프로젝트 전체에 적용되는 최소한의 정보만 담습니다. 기술 스택, 디렉토리 구조(`app/`, `api/`, `docs/`, `infra/`), 커밋 메시지 컨벤션, API 계약의 SSOT가 OpenAPI 스키마라는 점 등입니다. 약 40줄로, 어떤 세션에서든 항상 로드되면서도 컨텍스트를 과도하게 소비하지 않습니다.

`api/CLAUDE.md`는 백엔드 작업 시에만 온디맨드로 로드됩니다. 여기에는 아키텍처(Hexagonal + DDD), 의존성 방향, 핵심 패턴(Router → Facade → Use Case), 도메인 목록, 네이밍 규칙, 테스트 명령어 등 백엔드 개발에 필수적인 지시가 포함됩니다. 상세 설계 문서는 `@docs/backend-architecture.md`로 `@import`하여 Compaction을 생존시킵니다.

이 분리의 핵심은 **프론트엔드 작업 시 백엔드 규칙이 컨텍스트를 점유하지 않는 것**입니다. Flutter 코드를 수정할 때 Hexagonal Architecture 규칙이 로드되면 토큰만 낭비됩니다.

#### `.claude/rules/`: 계층별 조건부 규칙

rules 파일은 모두 `paths` 프론트매터를 가지고 있어, 해당 경로의 파일을 작업할 때만 로드됩니다.

| 파일 | paths | 역할 |
|------|-------|------|
| architecture.md | `api/**/*.py` | 의존성 방향, DI, 에러 처리 패턴 |
| domain.md | `api/src/domain/**` | import 제한(순수 Python만), Aggregate 규칙 |
| application.md | `api/src/application/**` | Use Case/Facade 1파일=1동작, Compensation |
| infrastructure.md | `api/src/infrastructure/**` | Repository/Adapter 네이밍, 폴더 구조 |
| presentation.md | `api/src/presentation/**` | Router → Facade만 호출, 예외 핸들러 |
| testing.md | `api/tests/**` | TDD, 4단계 테스트, Mock/Fake 전략, Contract Test |
| ml-pipeline.md | `api/src/infrastructure/gpu/**` | Modal 위임, 벡터 차원, dtype 규칙 |

이 설계에서 중요한 점은 **계층 경계 위반을 방지하는 규칙이 해당 계층 작업 시 자동으로 주입된다는 것**입니다. `domain/` 파일을 수정하면 "NEVER: FastAPI, SQLAlchemy를 import하지 않습니다"라는 규칙이 자동 로드됩니다. 에이전트가 스스로 규칙을 찾아 읽을 필요가 없습니다.

`architecture.md`만 `api/**/*.py` 전체를 대상으로 하는데, 이는 의존성 방향과 Router → Facade → Use Case 패턴이 어떤 계층을 작업하든 인지해야 하는 규칙이기 때문입니다.

#### `.claude/skills/`: 워크플로우 자동화

스킬은 특정 작업 흐름을 정의합니다. rules가 "무엇을 지켜야 하는가"라면, skills는 "어떤 순서로 수행하는가"입니다.

**글로브 기반 자동 적용 스킬**

일부 스킬은 `globs` 프론트매터를 가져, 매칭되는 파일 작업 시 자동으로 적용됩니다.

- `architecture`: `api/**/*` 경로에서 아키텍처 가이드를 자동 적용합니다
- `test-conventions`: 테스트 파일(`test_*`, `*_test.py`, `*_test.dart`) 작업 시 TDD 워크플로우(스펙 → 테스트 도출 → 레벨별 사이클)를 주입합니다
- `domain-docs`: `api/**/*`, `app/**/*` 작업 시 관련 도메인 문서 동기화를 안내합니다

**명시적 호출 스킬**

나머지 스킬은 사용자가 `/commit`, `/review 29`, `/test api` 등으로 직접 호출합니다. `review` 스킬은 Gemini가 먼저 리뷰를 남기고, Claude가 각 코멘트에 동의/반박 답글을 다는 2단 워크플로우를 정의합니다. `test` 스킬은 변경 영역을 감지하여 적절한 서브에이전트(api-test-runner 또는 app-test-runner)를 호출하는 오케스트레이터 역할을 합니다.

#### `.claude/agents/`: 전문 서브에이전트

에이전트는 특정 전문 영역에 대한 독립적인 페르소나입니다. 스킬이나 메인 에이전트가 필요에 따라 호출합니다.

| 에이전트 | 역할 | 격리 방식 |
|----------|------|-----------|
| api-reviewer | FastAPI 시니어 리뷰어. 계층 위반, Python 품질, DB/ML 패턴 검사 | worktree |
| app-reviewer | Flutter 시니어 리뷰어. 위젯 설계, 상태 관리, API 연동 검사 | worktree |
| api-test-runner | pytest QA 엔지니어. 레벨별 테스트 실행 및 분석 | 기본 |
| app-test-runner | Flutter test QA 엔지니어. 위젯/유닛 테스트 실행 및 분석 | 기본 |
| security-auditor | 보안 감사. OWASP Top 10 + 프로젝트 특화 검사 | worktree |

리뷰 에이전트들은 `isolation: worktree`로 설정되어, 메인 작업 디렉토리를 오염시키지 않고 독립된 워크트리에서 코드를 분석합니다. 테스트 러너는 실제 테스트를 실행해야 하므로 기본 환경에서 동작합니다.

각 에이전트는 해당 전문 분야의 체크리스트와 출력 형식을 내장하고 있어, 호출 시 별도의 지시 없이도 일관된 품질의 리뷰/분석 결과를 생산합니다.

#### Compaction 생존 전략의 적용

이 구조에서 Compaction 관점의 설계는 다음과 같습니다.

| 구성 요소 | Compaction 생존 | 이유 |
|-----------|----------------|------|
| 루트 CLAUDE.md | 생존 | 디스크에서 재주입 |
| api/CLAUDE.md | 비생존 (온디맨드) | 하위 디렉토리 파일을 읽을 때만 로드 |
| `@docs/backend-architecture.md` | 생존 | api/CLAUDE.md의 `@import`로 확장 |
| `.claude/rules/backend/*.md` | 조건부 생존 | `paths` 매칭 파일 작업 시 재주입 |
| `.claude/skills/*.md` | 해당 없음 | 워크플로우 호출 시에만 사용 |
| `.claude/agents/*.md` | 해당 없음 | 서브에이전트 생성 시 컨텍스트로 주입 |

핵심 아키텍처 규칙(의존성 방향, 에러 처리 패턴)은 `api/CLAUDE.md` 인라인 + `@import` + `rules/`의 3중 경로로 보장됩니다. 긴 작업 중 Compaction이 발생해도, 해당 계층의 파일을 다시 건드리는 순간 rules가 재로드되어 규칙이 복원됩니다.

반면, 커밋 메시지 생성이나 PR 생성 같은 워크플로우는 Compaction 생존이 불필요합니다. 이들은 작업 완료 후 1회성으로 호출하므로, 해당 시점에 스킬 파일이 로드되면 충분합니다.

---

## 관련 문서

- [[AI 네이티브 엔지니어]] - 에이전트 친화적 코드베이스 설계의 상위 맥락

---

## 참고 자료

- [Claude Code 공식 문서 - Memory](https://code.claude.com/docs/en/memory) - CLAUDE.md 로딩 메커니즘, @import, .claude/rules/ 공식 사양
- [GitHub Issue #6321 - File Import Behavior](https://github.com/anthropics/claude-code/issues/6321) - @import의 텍스트 치환 동작과 한계

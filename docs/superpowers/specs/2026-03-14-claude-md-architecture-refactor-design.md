# CLAUDE.md 아키텍처 리팩토링 설계

## 목적

현재 볼트의 CLAUDE.md 구조가 Claude Code 공식 아키텍처 가이드라인을 따르지 않고 있다. 이 리팩토링을 통해 Claude Code가 **정확한 컨텍스트를 정확한 시점에** 주입받는 구조로 전환한다.

## 현재 문제

1. **`@import` 안티패턴**: CLAUDE.md가 "작업 전 필수 확인" 목록으로 파일 경로만 나열. Claude가 자발적으로 읽어야 하는 구조.
2. **규칙 자동 로딩 부재**: `.claude/rules/` 디렉토리 미사용. 영역별 규칙이 `_meta/RULES.md`에 있으나 자동 주입되지 않음.
3. **루트 CLAUDE.md 비대**: 162줄. 사람을 위한 설명(볼트의 본질, 다루는 영역, 분석 시스템)이 AI 지시사항과 혼재.
4. **규칙 3중 중복**: 문체/용어/링크 규칙이 루트 CLAUDE.md, 하위 CLAUDE.md, _meta/RULES.md에 반복.
5. **컨텍스트 오염**: 영역과 무관한 규칙이 함께 로드되어 노이즈 발생.

## 설계 원칙

- **정밀 주입**: 작업 중인 영역에 맞는 규칙만 로드한다.
- **`@import` 불사용**: 이 볼트에서 `@import`는 파일 분리 편의일 뿐 성능상 이점이 없다. 사용하지 않는다.
- **하위 CLAUDE.md 불사용**: `.claude/rules/`가 영역별 규칙을 자동 주입하므로 하위 CLAUDE.md는 불필요하다.
- **INDEX/GLOSSARY 온디맨드**: 항상 로드하지 않고, rules 파일의 지시에 따라 필요 시 Claude가 읽는다.

---

## 변경 사항

### 1. 루트 CLAUDE.md 재작성

162줄 → ~20줄. 에이전트 정체성만 남긴다.

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

**제거 항목:**
- "분석 시스템" 섹션 (`.claude/commands/analyze.md`에 존재)
- "작업 전 필수 확인" 섹션 (`.claude/rules/` 자동 로드로 대체)
- "다루는 영역" 상세 설명 (볼트 구조 테이블로 대체)
- "공개 범위" 별도 섹션 (볼트 구조 테이블에 통합)
- "공통 작성 규칙" 섹션 (`.claude/rules/common.md`로 이동)
- "공통 프론트매터 형식" 섹션 (`.claude/rules/common.md`로 이동)
- "공통 링크 규칙" 섹션 (`.claude/rules/common.md`로 이동)

### 2. `.claude/rules/` 디렉토리 생성

```
.claude/rules/
├── common.md        # paths 없음 → 항상 로드
├── develop.md       # paths: ["develop/**"]
├── work.md          # paths: ["work/**"]
├── life.md          # paths: ["life/**"]
└── business.md      # paths: ["business/**"]
```

#### 2.1 common.md (paths 없음 — 항상 로드)

루트 CLAUDE.md에서 이동하는 공통 작성 규칙:

- 문체: "~니다" 체 공식 문어체. 구어체, 반말, 이모지 금지.
- 용어: 한글 우선. 최초 등장 시 개념 정의 필요한 경우에만 한글(English) 병기.
- 프론트매터: created, updated, tags, status YAML 형식.
- 링크: 내부 [[문서명]], 하단 ## 관련 문서, 외부 ## 참고 자료.
- 품질: 사내 보고서 수준. 추측/모호 표현 금지.
- 영역 인식: 작업 대상 영역이 명확하면 해당 영역의 파일을 먼저 읽거나 편집하여 영역별 규칙이 자동 로드되도록 한다.

#### 2.2 develop.md

```yaml
---
paths: ["develop/**"]
---
```

내용 — `develop/_meta/RULES.md`에서 이동:

- 영역 소개 (AI/데이터, 인프라/클라우드, 백엔드, 프론트엔드)
- 문서 유형별 섹션 구조 (개념, 튜토리얼, 문제 해결)
- 태그 체계 (유형 + 주제 + 상태)
- 작성 스타일 세부 (분량/구조 가이드, 명확성 기준)
- 품질 기준 체크리스트 + 지양 사항
- 지시: 새 문서 작성 시 `develop/_templates/CONCEPT.md` 템플릿을 기반으로 한다.
- 지시: 새 문서 작성 전 반드시 `develop/_meta/INDEX.md`를 읽어 중복을 방지한다.
- 지시: 새 용어 작성 시 `develop/_meta/GLOSSARY.md`를 확인한다.

**제거 (common.md로 이동했으므로):**
- 문체 규칙
- 용어 사용 규칙
- 링크 규칙

**제거 (커맨드 파일이 담당):**
- 문서 작성 워크플로우

#### 2.3 work.md

```yaml
---
paths: ["work/**"]
---
```

내용 — `work/_meta/RULES.md`에서 이동:

- 문서 유형별 섹션 구조 (프로젝트, 기술 의사결정, 노트, 문제 해결)
- 상태값 (draft, active, completed, archived)
- 태그 체계
- 지시: 새 문서 작성 전 반드시 `work/_meta/INDEX.md`를 읽어 중복을 방지한다.

#### 2.4 life.md

```yaml
---
paths: ["life/**"]
---
```

내용 — `life/_meta/RULES.md`에서 이동:

- 문서 유형 (생각/가치관, 의사결정, 회고)
- 상태값 (draft, done)
- 지시: 새 문서 작성 전 반드시 `life/_meta/INDEX.md`를 읽어 중복을 방지한다.
- 지시: 새 용어 작성 시 `life/_meta/GLOSSARY.md`를 확인한다.

#### 2.5 business.md

```yaml
---
paths: ["business/**"]
---
```

내용 — `business/_meta/RULES.md`에서 이동:

- 문서 유형별 섹션 구조 (브레인스토밍)
- 메타데이터 (domain 필드 포함)
- 상태값 (idea, exploring, validated, archived)
- 아이디어 평가 기준 (실현 가능성/시장성/차별성 5점 척도)
- 태그 체계
- 영역 간 링크 규칙 (develop/, work/ 적극 연결)
- 지시: 새 문서 작성 시 `business/_templates/BRAINSTORM.md` 템플릿을 기반으로 한다.
- 지시: 새 문서 작성 전 반드시 `business/_meta/INDEX.md`를 읽어 중복을 방지한다.
- 지시: 새 용어 작성 시 `business/_meta/GLOSSARY.md`를 확인한다.

### 3. 하위 CLAUDE.md 삭제

| 파일 | 조치 |
|------|------|
| `develop/CLAUDE.md` | 삭제 |
| `business/CLAUDE.md` | 삭제 |
| `work/CLAUDE.md` | 존재하지 않음 (변경 없음) |
| `life/CLAUDE.md` | 존재하지 않음 (변경 없음) |

### 4. `_meta/RULES.md` 삭제

| 파일 | 조치 |
|------|------|
| `develop/_meta/RULES.md` | 삭제 (`.claude/rules/develop.md`로 이동) |
| `work/_meta/RULES.md` | 삭제 (`.claude/rules/work.md`로 이동) |
| `life/_meta/RULES.md` | 삭제 (`.claude/rules/life.md`로 이동) |
| `business/_meta/RULES.md` | 삭제 (`.claude/rules/business.md`로 이동) |

### 5. 커맨드 파일 수정

확인 결과 커맨드 파일들은 `_meta/RULES.md`를 직접 참조하지 않는다. 주요 변경은 없으며, 기존 동작을 유지한다.

#### 5.1 `.claude/commands/write.md` — 변경 없음

- `_templates/CONCEPT.md` 템플릿 경로 유지
- INDEX/GLOSSARY 업데이트 지시 유지 (실제 액션)

#### 5.2 `.claude/commands/brainstorm.md` — 변경 없음

- `_templates/BRAINSTORM.md` 템플릿 경로 유지
- INDEX/GLOSSARY 업데이트 지시 유지

#### 5.3 `.claude/commands/analyze.md` — 변경 없음

- `_meta/INDEX.md` 읽기 지시 유지 (분석 대상)
- 페르소나 세부 지시 유지 (분석 시 톤 지정)

### 6. Obsidian 설정

`.obsidian/app.json`에 `"showHiddenFolders": true` 추가 — 이미 완료.

---

## 최종 구조

```
Obsidian Vault/
├── CLAUDE.md                    # ~20줄. 정체성 + 페르소나 + 구조
├── .claude/
│   ├── commands/
│   │   ├── analyze.md
│   │   ├── write.md
│   │   └── brainstorm.md
│   ├── rules/                   # NEW
│   │   ├── common.md            # 공통 작성 규칙 (항상 로드)
│   │   ├── develop.md           # develop 규칙 (조건부 로드)
│   │   ├── work.md              # work 규칙 (조건부 로드)
│   │   ├── life.md              # life 규칙 (조건부 로드)
│   │   └── business.md          # business 규칙 (조건부 로드)
│   └── settings.local.json
├── develop/
│   ├── _meta/
│   │   ├── INDEX.md             # 유지
│   │   └── GLOSSARY.md          # 유지
│   ├── _templates/
│   ├── concepts/
│   ├── tutorials/
│   ├── troubleshooting/
│   └── references/
├── work/
│   ├── _meta/
│   │   └── INDEX.md             # 유지 (GLOSSARY 없음)
│   └── ...
├── life/
│   ├── _meta/
│   │   ├── INDEX.md             # 유지
│   │   └── GLOSSARY.md          # 유지
│   └── ...
└── business/
    ├── _meta/
    │   ├── INDEX.md             # 유지
    │   └── GLOSSARY.md          # 유지
    ├── _templates/
    └── brainstorms/
```

## 컨텍스트 로딩 시나리오

| 작업 | 로드되는 컨텍스트 |
|------|---|
| 세션 시작 | 루트 CLAUDE.md (~20줄) + common.md |
| develop/ 문서 작성 | + develop.md → INDEX/GLOSSARY는 필요 시 읽기 |
| work/ 문서 수정 | + work.md → INDEX는 필요 시 읽기 |
| life/ 문서 작성 | + life.md → INDEX/GLOSSARY는 필요 시 읽기 |
| business/ 브레인스토밍 | + business.md → INDEX/GLOSSARY는 필요 시 읽기 |
| /analyze 실행 | + analyze.md 커맨드 로드 |

## 구현 순서

안전한 마이그레이션을 위해 다음 순서를 따른다:

1. `.claude/rules/` 파일 생성 (새 규칙 소스 확보)
2. 루트 CLAUDE.md 재작성
3. 하위 CLAUDE.md 삭제 (`develop/CLAUDE.md`, `business/CLAUDE.md`)
4. `_meta/RULES.md` 삭제 (4개 영역)
5. 검증: Claude Code 새 세션에서 규칙 로딩 확인

## 비고

- `work/_meta/`에는 GLOSSARY.md가 존재하지 않는다. 이는 현재 상태 그대로 유지한다.
- 하위 CLAUDE.md에 있던 영역 소개 테이블(주제 분류)은 각 영역 rules 파일 상단에 통합한다.

## 리팩토링 범위 외 (다음 작업)

- `_meta/` 디렉토리 네이밍 변경
- INDEX/GLOSSARY 구조 개선

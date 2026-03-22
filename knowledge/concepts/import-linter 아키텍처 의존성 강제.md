---
created: 2026-03-22
updated: 2026-03-22
tags: [concept, backend, architecture, tools]
status: done
---

# import-linter 아키텍처 의존성 강제

> import-linter는 파이썬 프로젝트의 모듈 간 의존성 방향을 선언적 계약으로 정의하고, CI에서 자동 검증하여 아키텍처 규칙을 강제하는 도구입니다.

---

## 1. 정의

import-linter는 파이썬 import 구문을 정적 분석하여 사전에 정의한 의존성 규칙 위반을 탐지하는 린팅 도구입니다. `pyproject.toml`에 계약(Contract)을 선언하면, `lint-imports` 명령으로 전체 코드베이스의 의존성 방향이 규칙에 부합하는지 검사합니다.

핵심 아이디어는 아키텍처 의존성 규칙을 **코드로 명시**하는 것입니다. 문서나 구두 합의가 아닌, CI 파이프라인에서 자동으로 실행되는 검증 도구를 통해 규칙 위반을 빌드 단계에서 차단합니다.

---

## 2. 등장 배경 및 필요성

### 2.1 코드 리뷰만으로는 아키텍처를 지킬 수 없습니다

- **리뷰어의 피로**: 수십 개 파일이 변경되는 PR에서 import 한 줄을 눈으로 잡아내기는 현실적으로 어렵습니다.
- **암묵적 규칙의 한계**: "도메인 계층은 인프라에 의존하지 않는다"는 규칙이 위키나 README에만 존재하면, 신규 팀원이 모르고 위반하거나 기존 팀원이 급한 일정에 무시합니다.
- **점진적 침식**: 한 번 허용된 잘못된 의존성은 다른 코드가 이를 참조하면서 빠르게 확산됩니다. 나중에 수정하려면 대규모 리팩토링이 필요합니다.

### 2.2 해결 방향

아키텍처 규칙을 **자동화된 검증**으로 전환해야 합니다. import-linter는 다음 문제를 해결합니다.

- **문제점 1**: 아키텍처 규칙이 코드 외부(문서, 구두)에만 존재하여 강제력이 없습니다.
- **문제점 2**: 규칙 위반을 사람이 수동으로 탐지해야 하므로 누락이 발생합니다.
- **문제점 3**: 위반이 감지되더라도 이미 병합된 후라면 되돌리기 어렵습니다.

---

## 3. 작동 원리 / 핵심 개념

### 3.1 선언적 계약

import-linter의 핵심은 **계약(Contract)** 입니다. 계약은 "어떤 모듈이 어떤 모듈을 import해서는 안 되는가"를 선언적으로 정의합니다. 주요 계약 유형은 다음과 같습니다.

| 계약 유형 | 설명 |
|-----------|------|
| `forbidden` | 특정 모듈이 지정된 모듈을 import하는 것을 금지합니다 |
| `independence` | 지정된 모듈들이 서로 import하지 않는 것을 보장합니다 |
| `layers` | 계층 간 의존성 방향을 상위→하위로만 허용합니다 |

### 3.2 정적 분석 방식

import-linter는 런타임에 코드를 실행하지 않습니다. AST(Abstract Syntax Tree) 수준에서 import 구문을 파싱하여 의존성 그래프를 구축하고, 이를 계약과 대조합니다. 따라서 테스트 커버리지에 영향받지 않으며, 코드 전체를 빠짐없이 검사합니다.

### 3.3 pyproject.toml 기반 설정

별도 설정 파일 없이 `pyproject.toml`에 `[tool.importlinter]` 섹션으로 설정합니다. 프로젝트 설정과 한 곳에서 관리할 수 있어 유지보수가 용이합니다.

---

## 4. 장점 및 이점

- **아키텍처 규칙의 코드화**: 문서가 아닌 코드로 규칙을 정의하므로, 규칙 자체가 버전 관리되고 리뷰 대상이 됩니다.
- **자동 검증**: CI 파이프라인에서 매 PR마다 자동 실행되어 위반을 병합 전에 차단합니다.
- **낮은 도입 비용**: 기존 프로젝트에 설정 몇 줄만 추가하면 즉시 적용 가능합니다. 코드 변경이 필요 없습니다.
- **명확한 오류 메시지**: 어떤 모듈이 어떤 규칙을 위반했는지 구체적으로 알려주어, 개발자가 즉시 수정할 수 있습니다.
- **팀 온보딩 효율화**: 신규 팀원이 아키텍처 규칙을 몰라도, CI가 잘못된 import를 자동으로 거부합니다.

---

## 5. 한계점 및 고려사항

- **import 수준 검사에 한정**: 모듈 간 의존성만 검사합니다. 함수 호출 패턴이나 데이터 흐름까지는 분석하지 못합니다.
- **동적 import 미탐지**: `importlib.import_module()`과 같은 동적 import는 정적 분석으로 탐지할 수 없습니다.
- **패키지 구조 전제**: `root_packages` 설정이 올바른 패키지 구조를 전제합니다. 패키지 구조가 비정형이면 설정이 복잡해질 수 있습니다.
- **계약 설계 역량 필요**: 어떤 의존성을 금지할지는 아키텍처에 대한 이해가 선행되어야 합니다. 도구는 규칙을 강제할 뿐, 올바른 규칙을 만들어주지는 않습니다.

---

## 6. 실무 적용 가이드

### 6.1 설치 및 기본 설정

개발 의존성으로 설치합니다.

```toml
# pyproject.toml
[project.optional-dependencies]
dev = [
    "import-linter>=2.1",
]
```

루트 패키지를 설정합니다.

```toml
[tool.importlinter]
root_packages = ["src"]
include_external_packages = true
```

`include_external_packages = true`는 외부 라이브러리(fastapi, sqlalchemy 등)에 대한 의존성도 검사 대상에 포함하는 설정입니다. [[Hexagonal Architecture 실전 적용|헥사고날 아키텍처]]에서 도메인 순수성을 보장하려면 이 설정이 필수적입니다.

### 6.2 계약 정의 — Unlook 프로젝트 실무 예시

Unlook 프로젝트에서는 3개의 계약으로 헥사고날 아키텍처의 의존성 방향을 강제합니다.

**계약 1: 도메인 계층 순수성 보장**

```toml
[[tool.importlinter.contracts]]
name = "domain 계층은 다른 계층에 의존하지 않습니다"
type = "forbidden"
source_modules = ["src.domain"]
forbidden_modules = [
    "src.application",
    "src.presentation",
    "src.infrastructure",
    "fastapi",
    "sqlalchemy",
    "pydantic",
    "httpx",
    "PIL",
]
```

도메인 계층이 프레임워크나 외부 라이브러리에 의존하지 않도록 합니다. 이를 통해 도메인 로직을 순수한 파이썬 코드로 유지할 수 있습니다.

**계약 2: 애플리케이션→프레젠테이션 의존 금지**

```toml
[[tool.importlinter.contracts]]
name = "application 계층은 presentation에 의존하지 않습니다"
type = "forbidden"
source_modules = ["src.application"]
forbidden_modules = ["src.presentation"]
```

유스케이스 계층이 HTTP/API 계층에 의존하는 것을 방지합니다. 애플리케이션 로직은 전달 방식(REST, gRPC, CLI 등)과 무관해야 합니다.

**계약 3: 프레젠테이션→인프라스트럭처 의존 금지**

```toml
[[tool.importlinter.contracts]]
name = "presentation 계층은 infrastructure에 의존하지 않습니다"
type = "forbidden"
source_modules = ["src.presentation"]
forbidden_modules = ["src.infrastructure"]
```

API 라우터가 데이터베이스 세션이나 ORM 모델에 직접 접근하는 것을 방지합니다. 프레젠테이션 계층은 애플리케이션 계층의 인터페이스만 호출해야 합니다.

### 6.3 CI 파이프라인 통합

GitHub Actions에서 린트 단계에 `lint-imports`를 추가합니다.

```yaml
# .github/workflows/api.yml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
      - run: cd api && uv sync --extra dev
      - run: cd api && uv run ruff check .
      - run: cd api && uv run ruff format --check .
      - run: cd api && uv run lint-imports
```

`lint-imports`는 ruff 등 다른 린터와 함께 실행됩니다. 코드 스타일과 아키텍처 규칙을 한 번의 CI 실행에서 모두 검증합니다. 위반 시 PR 병합이 차단되므로, 아키텍처 규칙이 자연스럽게 강제됩니다.

### 6.4 도입 절차

1. `pyproject.toml`에 import-linter 의존성을 추가합니다.
2. `[tool.importlinter]` 섹션에 루트 패키지를 설정합니다.
3. 현재 아키텍처의 의존성 방향을 분석하여 계약을 정의합니다.
4. 로컬에서 `lint-imports`를 실행하여 기존 위반 사항을 확인하고 수정합니다.
5. CI 파이프라인에 `lint-imports` 단계를 추가합니다.
6. 팀에 계약 목적과 위반 시 대처 방법을 공유합니다.

---

## 관련 문서

- [[Hexagonal Architecture 실전 적용]] - import-linter로 의존성 방향을 강제하는 대상 아키텍처

---

## 참고 자료

- [import-linter 공식 문서](https://import-linter.readthedocs.io/) - 계약 유형별 상세 설정 가이드
- [import-linter GitHub](https://github.com/seddonym/import-linter) - 소스 코드 및 릴리스 정보

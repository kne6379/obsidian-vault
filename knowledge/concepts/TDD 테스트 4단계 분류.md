---
created: 2026-03-22
updated: 2026-03-22
tags: [concept, backend, testing]
status: done
---

# TDD 테스트 4단계 분류

> 테스트 주도 개발(Test-Driven Development)의 Red-Green-Refactor 사이클과, 테스트를 unit/domain, unit/application, integration, e2e 4단계로 분류하여 계층별 책임을 명확히 검증하는 전략입니다.

---

## 1. 정의

TDD는 구현 코드보다 테스트를 먼저 작성하고, 테스트를 통과시키는 최소한의 코드를 구현한 뒤, 리팩터링하는 개발 방법론입니다. 3단계 사이클로 구성됩니다:

1. **Red**: 실패하는 테스트를 먼저 작성합니다.
2. **Green**: 테스트를 통과시키는 최소한의 구현을 작성합니다.
3. **Refactor**: 테스트가 통과하는 상태를 유지하며 코드를 개선합니다.

테스트 4단계 분류는 [[Hexagonal Architecture 실전 적용|헥사고날 아키텍처]]의 계층 구조에 대응하여 테스트를 네 단계로 나누는 전략입니다. 각 단계는 검증 대상, 의존성 범위, 실행 속도가 다르며, 안쪽 계층부터 바깥 계층 순서로 TDD 사이클을 진행합니다.

---

## 2. 등장 배경 및 필요성

- **"테스트는 있지만 무엇을 검증하는지 불분명한" 코드베이스**: 테스트 수는 많지만 계층별 책임이 혼재되어, 하나의 변경이 무관한 테스트를 연쇄적으로 깨뜨리는 문제가 발생합니다.
- **느린 피드백 루프**: 모든 테스트가 데이터베이스에 의존하면, 단순한 도메인 규칙 변경에도 전체 테스트 실행 시간이 길어집니다.
- **아키텍처 경계 침범 감지 어려움**: 도메인 계층이 인프라에 의존하는 위반을 테스트 수준에서 조기에 발견할 수 없습니다.
- **CI 파이프라인 최적화 필요**: 빠른 단위 테스트와 느린 통합 테스트를 분리하여 병렬 실행하고 피드백 시간을 단축해야 합니다.

---

## 3. 작동 원리 / 핵심 개념

### 3.1 4단계 테스트 분류

| 단계 | 검증 대상 | 의존성 | 속도 | 비동기 |
|------|-----------|--------|------|--------|
| unit/domain | 엔티티, 값 객체, 도메인 서비스 | 없음 (순수 Python) | 가장 빠름 | sync |
| unit/application | 유스케이스, 파사드 | 포트를 Fake로 대체 | 빠름 | async |
| integration | 리포지토리, 어댑터 | 실제 DB (로컬 PostgreSQL) | 보통 | async |
| e2e | 전체 계층 통합 | 실제 DB + TestClient | 느림 | async |

### 3.2 TDD 사이클과 4단계의 결합

4단계 분류는 TDD 사이클의 적용 순서이기도 합니다. 안쪽 계층(도메인)부터 바깥 계층(프레젠테이션)까지 순서대로 Red-Green을 반복합니다:

```
unit/domain 테스트 작성 → pytest → FAILED 확인
  → domain 구현 → pytest → PASSED 확인
unit/application 테스트 작성 → pytest → FAILED 확인
  → application 구현 → pytest → PASSED 확인
integration 테스트 작성 → pytest → FAILED 확인
  → infrastructure 구현 → pytest → PASSED 확인
e2e 테스트 작성 → pytest → FAILED 확인
  → presentation 구현 + containers.py 조립 → pytest → PASSED 확인
```

이 순서는 [[Hexagonal Architecture 실전 적용|헥사고날 아키텍처]]의 의존성 방향(`presentation → application → domain ← infrastructure`)과 정확히 일치합니다. 도메인이 가장 먼저 안정화되고, 인프라와 프레젠테이션은 마지막에 조립됩니다.

### 3.3 스펙 문서에서 테스트 케이스 도출

스펙 문서의 각 항목은 테스트 케이스로 직접 매핑됩니다:

| 스펙 항목 | 테스트 매핑 |
|-----------|-----------|
| 결과 | 관련 레벨마다 성공 케이스 1개 |
| 예외 상황 | 관련 레벨마다 실패 케이스 1개 |
| 입력 항목 (필수 조건) | 검증 실패 케이스 1개 |
| 인수 조건 | 결과/예외와 중복되면 생성 안 함 |

검증 대상에 따라 적절한 레벨을 선택합니다:

| 검증 대상 | 레벨 |
|-----------|------|
| 도메인 규칙 | unit/domain |
| 유스케이스 조율 | unit/application |
| DB 쿼리 결과 | integration |
| API 계약 (HTTP 상태 코드, 응답 형식) | e2e |

### 3.4 Contract Test 패턴

유닛 테스트에서 포트(Port)를 Fake로 대체할 때, Fake가 실제 구현체와 동일하게 동작하는지 보장해야 합니다. Contract Test는 하나의 추상 테스트 클래스를 정의하고, Fake와 Real 양쪽에서 동일한 테스트를 실행하여 이를 검증합니다.

```python
# tests/contracts/test_auth_repository_contract.py
import abc
import pytest


class AuthRepositoryContract(abc.ABC):
    """Fake와 Real이 동일하게 통과해야 하는 계약"""

    @abc.abstractmethod
    def get_repository(self):
        """테스트 대상 리포지토리 인스턴스를 반환합니다"""

    @pytest.mark.asyncio
    async def test_should_return_none_when_user_not_found(self):
        repo = self.get_repository()
        result = await repo.find_by_id("nonexistent-id")
        assert result is None

    @pytest.mark.asyncio
    async def test_should_save_and_retrieve_user(self):
        repo = self.get_repository()
        user = create_user()  # factories 활용
        await repo.save(user)
        found = await repo.find_by_id(user.id)
        assert found.id == user.id
```

```python
# tests/unit/fakes/auth/test_fake_auth_repository.py
from tests.contracts.test_auth_repository_contract import AuthRepositoryContract


class TestFakeAuthRepository(AuthRepositoryContract):
    def get_repository(self):
        return FakeAuthRepository()
```

```python
# tests/integration/infrastructure/auth/test_auth_repository.py
from tests.contracts.test_auth_repository_contract import AuthRepositoryContract


class TestAuthRepository(AuthRepositoryContract):
    def get_repository(self):
        return AuthRepository(session=self.session)
```

Fake가 Contract Test를 통과하면, unit/application 레벨에서 해당 Fake를 안전하게 사용할 수 있습니다.

### 3.5 Mock/Fake 전략

| 레벨 | 전략 |
|------|------|
| unit/domain | 외부 의존성 없음. 순수 Python만 사용 |
| unit/application | 포트에 대한 Fake 구현체만 사용. 도메인 객체는 실제를 사용 |
| integration | 실제 DB 사용. 외부 서비스(GPU 추론, 오브젝트 스토리지 등)만 mock |
| e2e | 실제 DB + TestClient. 인증은 JWT fixture로 처리 |

핵심 원칙은 "도메인 객체는 절대 mock하지 않는다"입니다. Fake는 포트 인터페이스를 구현하는 인메모리 대체물이며, `unittest.mock.MagicMock`과는 다릅니다. Fake는 실제 동작을 간소화하여 구현하므로 테스트의 신뢰성이 높습니다.

---

## 4. 장점 및 이점

- **빠른 피드백**: unit/domain 테스트는 외부 의존성 없이 밀리초 단위로 실행됩니다. 도메인 규칙 변경 시 즉시 검증할 수 있습니다.
- **계층 간 책임 분리 강제**: 도메인 테스트에서 import할 수 없는 모듈이 있다면, 아키텍처 위반의 징후입니다.
- **장애 격리**: integration 테스트가 실패하면 DB 쿼리 문제, unit/application 테스트가 실패하면 유스케이스 조율 문제로 원인을 즉시 좁힐 수 있습니다.
- **CI 최적화**: lint, unit, db(integration + e2e) 잡을 병렬로 실행하여 전체 파이프라인 시간을 단축합니다.
- **리팩터링 안전망**: 테스트 피라미드가 갖추어지면, 내부 구현을 변경해도 각 계층의 계약이 유지되는지 자동으로 확인됩니다.

---

## 5. 한계점 및 고려사항

- **초기 구축 비용**: 4단계 디렉토리 구조, Fake 구현체, Contract Test, conftest.py 등 테스트 인프라를 먼저 갖추어야 합니다.
- **Fake 유지 비용**: 포트 인터페이스가 변경될 때 Fake도 함께 수정해야 합니다. Contract Test가 이 불일치를 잡아주지만, 관리 대상이 늘어납니다.
- **과도한 분류의 위험**: 소규모 프로젝트에서는 4단계가 오히려 부담이 될 수 있습니다. 헥사고날 아키텍처를 채택한 중규모 이상의 프로젝트에 적합합니다.
- **테스트 간 중복**: 동일한 시나리오가 여러 레벨에서 반복 검증될 수 있습니다. 각 레벨은 자신의 계층 책임만 검증하도록 범위를 명확히 제한해야 합니다.

---

## 6. 실무 적용 가이드

### 6.1 디렉토리 구조

```
api/tests/
├── conftest.py              # 공통 (pytest 옵션, JWT factory)
├── test_architecture.py     # 아키텍처 구조 검증
├── contracts/               # Port Contract (추상 테스트)
├── factories/               # 테스트 데이터 팩토리
├── unit/
│   ├── conftest.py          # Fake 구현체 fixture
│   ├── fakes/{도메인}/      # Port Fake 구현체
│   ├── domain/{도메인}/     # 순수 도메인 로직 (sync)
│   └── application/{도메인}/ # Use Case/Facade (async, Fake)
├── integration/
│   ├── conftest.py          # DB 세션, 트랜잭션 롤백
│   └── infrastructure/{도메인}/
└── e2e/
    ├── conftest.py          # TestClient, DB, JWT
    └── {도메인}/
```

### 6.2 네이밍 컨벤션

- **파일명**: `test_*.py`
- **함수명**: `test_should_[동작]_when_[조건]`
- **코드 구조**: AAA 패턴 (Arrange → Act → Assert)

```python
# tests/unit/domain/auth/test_user.py

def test_should_raise_error_when_nickname_exceeds_max_length():
    # Arrange
    long_nickname = "a" * 21

    # Act & Assert
    with pytest.raises(InvalidNicknameError):
        User.create(nickname=long_nickname, provider="kakao")
```

### 6.3 팩토리 패턴

```python
# tests/factories/auth.py

def create_user(
    *,
    user_id: str = "test-user-id",
    nickname: str = "테스트유저",
    provider: str = "kakao",
) -> User:
    """기본값은 정상 케이스. 필요한 값만 오버라이드합니다."""
    return User(id=user_id, nickname=nickname, provider=provider)
```

### 6.4 CI 파이프라인 분리

```yaml
# .github/workflows/api.yml
jobs:
  lint:
    steps:
      - run: uv run ruff check .
      - run: uv run ruff format --check .
      - run: uv run lint-imports     # 의존성 방향 검증

  test-unit:
    steps:
      - run: uv run pytest tests/test_architecture.py tests/unit/ --tb=short -q

  test-db:
    services:
      postgres:
        image: pgvector/pgvector:pg16
    steps:
      - run: uv run pytest tests/integration/ tests/e2e/ --tb=short -q
```

세 잡은 병렬로 실행됩니다. `lint`와 `test-unit`은 DB 없이 빠르게 완료되고, `test-db`만 PostgreSQL 서비스 컨테이너를 사용합니다. `lint-imports`는 import 방향 규칙(domain이 infrastructure를 import하지 않는지 등)을 정적으로 검사합니다.

### 6.5 실행 명령어

```bash
make test                    # 전체 테스트
make test-unit               # unit만 (DB 불필요)
make test-integration        # integration (로컬 DB 필요)
make test-e2e                # e2e (로컬 DB 필요)
pytest tests/unit/domain/    # domain 레벨만
```

---

## 관련 문서

- [[Hexagonal Architecture 실전 적용]] - 4단계 분류의 기반이 되는 아키텍처 패턴

---

## 참고 자료

- [Kent Beck, "Test Driven Development: By Example"](https://www.oreilly.com/library/view/test-driven-development/0321146530/) - TDD 원전
- [pytest 공식 문서](https://docs.pytest.org/) - 테스트 프레임워크
- [pytest-asyncio](https://pytest-asyncio.readthedocs.io/) - 비동기 테스트 지원

---
created: 2026-03-22
updated: 2026-03-22
tags: [concept, backend, architecture]
status: done
---

# Hexagonal Architecture 실전 적용

> 헥사고날 아키텍처(Ports & Adapters)를 FastAPI 프로젝트에 실제 적용하며 정립한 4계층 구조, 의존성 규칙, 패턴 선택 기준을 정리한 문서입니다.

---

## 1. 정의

헥사고날 아키텍처(Hexagonal Architecture)는 Alistair Cockburn이 제안한 소프트웨어 설계 패턴으로, 포트와 어댑터(Ports & Adapters) 아키텍처라고도 합니다. 핵심 비즈니스 로직(도메인)을 중심에 두고, 외부 시스템과의 연결을 포트(인터페이스)와 어댑터(구현체)로 분리하여 도메인이 기술 선택에 의존하지 않도록 설계합니다.

이 문서는 이론 설명이 아닌, FastAPI 기반 프로젝트(Unlook)에서 실제로 적용하며 얻은 구조적 판단과 패턴을 중심으로 서술합니다.

---

## 2. 등장 배경 및 필요성

전통적인 계층형 아키텍처(Controller → Service → Repository)에서는 다음 문제가 반복됩니다.

- **비즈니스 로직과 기술 코드의 혼재**: 서비스 계층에 SQLAlchemy 쿼리, HTTP 클라이언트 호출, 파일 저장 로직이 뒤섞여 테스트와 변경이 어려워집니다.
- **의존성 방향의 모호함**: 도메인 규칙이 프레임워크나 ORM에 의존하면, 기술 교체 시 비즈니스 로직까지 수정해야 합니다.
- **교체 불가능한 외부 서비스**: 저장소를 S3에서 R2로, 인증을 Firebase에서 Supabase로 바꿀 때 비즈니스 로직 전체를 건드리는 상황이 발생합니다.

헥사고날 아키텍처는 "도메인은 순수하게, 외부는 교체 가능하게"라는 원칙으로 이 문제들을 해결합니다.

---

## 3. 작동 원리 / 핵심 개념

### 3.1 4계층 구조

Unlook 프로젝트에서는 헥사고날 아키텍처를 4개 계층으로 구체화했습니다.

```
┌──────────────────────────────────┐
│  infrastructure (가장 바깥)        │
│  ┌────────────────────────────┐  │
│  │  presentation               │  │
│  │  ┌──────────────────────┐  │  │
│  │  │  application          │  │  │
│  │  │  ┌────────────────┐  │  │  │
│  │  │  │  domain (중심)   │  │  │  │
│  │  │  └────────────────┘  │  │  │
│  │  └──────────────────────┘  │  │
│  └────────────────────────────┘  │
└──────────────────────────────────┘
```

| 계층 | 역할 | 허용되는 import |
|------|------|----------------|
| domain | 순수 비즈니스 규칙 | Python 표준 라이브러리만 |
| application | 유스케이스 흐름 조율 | domain |
| presentation | HTTP 입출력 | application, domain |
| infrastructure | 외부 시스템 실제 연결 | domain(포트 구현) |

의존성 방향은 반드시 바깥에서 안쪽으로만 향합니다.

```
presentation → application → domain ← infrastructure
```

domain은 어떤 계층도 알지 못합니다. infrastructure는 domain의 포트를 구현하므로 화살표가 domain을 향합니다.

### 3.2 포트와 어댑터

**포트**는 domain 계층에 정의된 ABC 인터페이스입니다. 외부 기능이 필요하지만, 구체적인 기술은 모르는 상태에서 "이런 기능이 필요하다"고 선언만 합니다.

**어댑터**는 infrastructure 계층에서 포트를 실제로 구현한 클래스입니다.

```python
# domain/media/ports/storage_port.py — 포트 (도메인이 정의)
from abc import ABC, abstractmethod

class StoragePort(ABC):
    @abstractmethod
    async def upload(self, file: bytes, key: str) -> str: ...

    @abstractmethod
    async def delete(self, key: str) -> None: ...
```

```python
# infrastructure/storage/r2_storage_adapter.py — 어댑터 (인프라가 구현)
class R2StorageAdapter(StoragePort):
    async def upload(self, file: bytes, key: str) -> str:
        # Cloudflare R2 SDK 호출
        ...

    async def delete(self, key: str) -> None:
        # R2 객체 삭제
        ...
```

포트 사용 여부는 교체 가능성을 기준으로 판단합니다.

| 대상 | 교체 가능성 | 포트 사용 |
|------|-----------|----------|
| DB (PostgreSQL) | 있음 | O (RepositoryPort) |
| 파일 저장소 (Cloudflare R2) | 있음 | O (StoragePort) |
| GPU 추론 (Modal) | 있음 | O (InferencePort) |
| 인증 (Supabase Auth) | 있음 | O (AuthProviderPort) |
| 이미지 처리 (PIL) | 낮음 | X (Processor로 직접 배치) |

### 3.3 퍼사드 패턴

모든 라우터는 반드시 퍼사드(Facade)를 통해서만 application 계층에 접근합니다. 퍼사드는 1파일 = 1동작 원칙을 따르며, `execute()` 메서드 하나만 가집니다.

**단일 도메인 퍼사드**: 하나의 유스케이스를 감싸는 진입점입니다.

```python
# application/facades/upload_photo_facade.py
class UploadPhotoFacade:
    def __init__(self, use_case: UploadPhotoUseCase):
        self.use_case = use_case

    async def execute(self, user_id: str, file: bytes, filename: str):
        return await self.use_case.execute(user_id, file, filename)
```

**크로스 도메인 퍼사드**: 여러 도메인의 유스케이스를 조합하는 진입점입니다.

```python
# application/facades/signup_facade.py
class SignupFacade:
    def __init__(self, signup: SignupUseCase, upload: UploadPhotoUseCase):
        self.signup = signup
        self.upload = upload

    async def execute(self, data):
        user = await self.signup.execute(data)
        await self.upload.execute(user.id, data.photos)
        return user
```

퍼사드를 도입한 이유는 명확합니다. 라우터가 유스케이스를 직접 호출하면, 크로스 도메인 동작 시 라우터에 오케스트레이션 로직이 스며듭니다. 퍼사드 계층을 두면 "이 API가 어떤 동작을 수행하는가"를 코드 구조만으로 파악할 수 있습니다.

```
Router → Facade → Use Case(s)
```

### 3.4 의존성 주입

DI 프레임워크 없이, 수동 팩토리 + FastAPI `Depends()` 조합으로 의존성을 주입합니다. 모든 조립은 `containers.py` 한 곳에서 이루어집니다.

```python
# containers.py
async def get_session():
    async with async_session_factory() as session:
        yield session

def get_media_repository(
    session: AsyncSession = Depends(get_session),
) -> MediaRepositoryPort:
    return MediaRepository(session=session)

def get_upload_photo_use_case(
    repo: MediaRepositoryPort = Depends(get_media_repository),
    storage: StoragePort = Depends(get_storage_adapter),
) -> UploadPhotoUseCase:
    return UploadPhotoUseCase(repo=repo, storage=storage)

def get_upload_photo_facade(
    use_case: UploadPhotoUseCase = Depends(get_upload_photo_use_case),
) -> UploadPhotoFacade:
    return UploadPhotoFacade(use_case=use_case)
```

팩토리 함수의 반환 타입을 포트(ABC)로 선언하면, 라우터나 유스케이스는 구현체를 전혀 모른 채로 동작합니다. request-scoped 세션을 통해 한 요청 안에서 트랜잭션이 쪼개지지 않도록 보장합니다.

### 3.5 도메인 예외에서 HTTP 응답으로의 변환

도메인 계층은 HTTP 상태 코드를 알지 못합니다. 비즈니스 규칙 위반은 도메인 예외로 표현하고, presentation 계층의 `exception_handlers.py`에서 일괄 변환합니다.

```python
# shared/base_exception.py
class DomainException(Exception):
    pass

# domain/media/exceptions.py
class PhotoLimitExceededError(DomainException):
    pass

# presentation/exception_handlers.py
@app.exception_handler(PhotoLimitExceededError)
async def handle_photo_limit(request, exc):
    return JSONResponse(status_code=400, content={"detail": str(exc)})
```

이 패턴의 핵심 규칙은 두 가지입니다.

1. domain/application 계층에서 `HTTPException`을 절대 raise하지 않습니다.
2. 라우터 내부에서 `try/except`로 도메인 예외를 잡지 않습니다.

### 3.6 import-linter로 의존성 방향 강제

규칙은 문서에만 존재하면 반드시 깨집니다. `import-linter`를 `pyproject.toml`에 설정하여 CI에서 의존성 방향 위반을 자동 검출합니다.

```toml
[tool.importlinter]
root_packages = ["src"]
include_external_packages = true

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

[[tool.importlinter.contracts]]
name = "application 계층은 presentation에 의존하지 않습니다"
type = "forbidden"
source_modules = ["src.application"]
forbidden_modules = ["src.presentation"]

[[tool.importlinter.contracts]]
name = "presentation 계층은 infrastructure에 의존하지 않습니다"
type = "forbidden"
source_modules = ["src.presentation"]
forbidden_modules = ["src.infrastructure"]
```

domain에서 외부 라이브러리(FastAPI, SQLAlchemy, Pydantic 등)까지 금지 목록에 포함시킨 점이 중요합니다. 이렇게 하면 도메인 순수성이 도구 수준에서 보장됩니다.

---

## 4. 장점 및 이점

- **테스트 용이성**: 도메인 계층은 외부 의존성이 없으므로, 모킹 없이 순수 단위 테스트가 가능합니다. 포트를 가짜 구현체로 교체하면 application 계층 테스트도 DB 없이 수행할 수 있습니다.
- **기술 교체의 격리**: 저장소를 S3에서 R2로, 인증을 Firebase에서 Supabase로 바꿀 때 어댑터만 교체하면 됩니다. 도메인과 유스케이스 코드는 변경하지 않습니다.
- **코드 구조로 드러나는 설계 의도**: 디렉토리 구조 자체가 아키텍처 다이어그램 역할을 합니다. 새로운 팀원이 코드를 처음 보더라도 계층 간 관계와 데이터 흐름을 즉시 파악할 수 있습니다.
- **도메인 로직의 장기 생존**: 비즈니스 규칙은 기술 선택보다 오래 살아남습니다. 프레임워크가 바뀌어도 도메인 코드는 그대로 재사용할 수 있습니다.

---

## 5. 한계점 및 고려사항

- **초기 보일러플레이트 증가**: 포트, 어댑터, 퍼사드, 팩토리를 각각 정의해야 하므로 파일 수가 전통적 구조 대비 2~3배 늘어납니다. 단순 CRUD에서는 과잉 설계가 될 수 있습니다.
- **간접 참조 비용**: 라우터 → 퍼사드 → 유스케이스 → 포트 → 어댑터로 이어지는 호출 경로가 길어져, 코드를 추적할 때 여러 파일을 넘나들어야 합니다.
- **팀 학습 곡선**: 포트/어댑터 개념, 의존성 역전 원칙, 계층별 import 규칙 등을 팀 전원이 이해해야 합니다. 규칙을 문서로만 공유하면 반드시 위반이 발생하므로, import-linter 같은 자동 검증 도구가 필수입니다.
- **DI 컨테이너의 관리 부담**: 프로젝트가 커지면 `containers.py`의 팩토리 함수도 비례하여 증가합니다. 도메인 6개, 각 도메인당 유스케이스 3~5개일 때 이미 수십 개의 팩토리가 필요합니다.

---

## 6. 실무 적용 가이드

### 6.1 적용 판단 기준

헥사고날 아키텍처가 효과적인 경우와 과잉인 경우를 구분해야 합니다.

**적용이 적합한 경우:**

- 도메인 로직이 복잡하고, 비즈니스 규칙이 자주 변경되는 프로젝트
- 외부 서비스(DB, 저장소, 인증, GPU 추론 등)가 2개 이상이고, 교체 가능성이 있는 경우
- 장기 운영을 전제로 하여, 테스트와 유지보수성이 중요한 경우
- 여러 도메인이 독립적으로 발전해야 하는 경우

**적용을 재고해야 하는 경우:**

- 단순 CRUD 위주의 소규모 프로젝트
- 프로토타입이나 PoC처럼 빠른 검증이 목적인 경우
- 외부 서비스가 1개뿐이고 교체 가능성이 거의 없는 경우
- 팀 전체가 아키텍처를 이해하고 합의할 여력이 없는 경우

### 6.2 도입 절차

FastAPI 프로젝트에 헥사고날 아키텍처를 적용하는 단계별 절차입니다.

**1단계: 디렉토리 골격 생성**

```
src/
├── domain/{도메인}/
│   ├── aggregates.py
│   ├── entities.py
│   ├── value_objects.py
│   ├── exceptions.py
│   ├── enums.py
│   ├── services/
│   └── ports/
├── application/{도메인}/
│   ├── {동작}_{대상}_use_case.py
│   └── schemas/
├── application/facades/
│   └── {동작}_{대상}_facade.py
├── presentation/{도메인}/
│   └── {도메인}_router.py
├── infrastructure/{도메인}/
│   ├── {도메인}_repository.py
│   └── {도메인}_models.py
├── shared/
└── containers.py
```

**2단계: 도메인부터 작성**

도메인 계층을 먼저 작성합니다. 순수 Python만 사용하여 비즈니스 규칙을 표현하고, 외부 기능이 필요한 부분은 포트로 정의합니다.

**3단계: import-linter 설정**

`pyproject.toml`에 의존성 규칙을 설정하여, 도메인 순수성을 CI 단계에서 강제합니다.

**4단계: 유스케이스와 퍼사드 작성**

application 계층에서 포트 인터페이스에만 의존하는 유스케이스를 작성하고, 퍼사드로 감쌉니다.

**5단계: DI 조립**

`containers.py`에서 팩토리 함수를 정의하여, 포트와 어댑터를 연결합니다. 반환 타입은 반드시 포트 타입으로 선언합니다.

**6단계: 라우터와 예외 변환**

presentation 계층에서 퍼사드를 호출하고, `exception_handlers.py`에서 도메인 예외를 HTTP 응답으로 변환합니다.

### 6.3 네이밍 규칙 요약

| 계층 | 접미사 | 파일명 패턴 | 예시 |
|------|--------|------------|------|
| domain | Port | `{역할}_port.py` | `storage_port.py` |
| application | UseCase | `{동작}_{대상}_use_case.py` | `upload_photo_use_case.py` |
| application | Facade | `{동작}_{대상}_facade.py` | `upload_photo_facade.py` |
| infrastructure | Repository | `{도메인}_repository.py` | `auth_repository.py` |
| infrastructure | Adapter | `{프로바이더}_{역할}_adapter.py` | `r2_storage_adapter.py` |
| infrastructure | Processor | `{역할}_processor.py` | `image_processor.py` |

폴더명은 역할 기준으로 작성하며, 프로바이더명을 폴더명에 사용하지 않습니다(예: `storage/` O, `r2/` X).

---

## 관련 문서

- [[API Gateway]] - MSA 환경에서 헥사고날 아키텍처와 함께 사용되는 진입점 패턴
- [[CLAUDE.md 설계 원칙]] - 계층별 규칙을 CLAUDE.md로 관리하는 설계 사례
- [[PostgreSQL 내부 구조와 성능 최적화]] - infrastructure 계층의 DB 어댑터가 다루는 대상

---

## 참고 자료

- [Alistair Cockburn - Hexagonal Architecture](https://alistair.cockburn.us/hexagonal-architecture/) - 원저자의 아키텍처 정의
- [import-linter 공식 문서](https://import-linter.readthedocs.io/) - Python 의존성 방향 강제 도구
- [FastAPI 공식 문서 - Dependencies](https://fastapi.tiangolo.com/tutorial/dependencies/) - Depends()를 활용한 DI 패턴

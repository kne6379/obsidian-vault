---
created: 2026-03-22
updated: 2026-03-22
tags: [concept, backend, database]
status: done
---

# Alembic DB 마이그레이션

> Alembic은 SQLAlchemy 기반 파이썬 프로젝트에서 데이터베이스 스키마 변경을 버전 관리하고 자동화하는 마이그레이션 도구입니다.

---

## 1. 정의

Alembic은 SQLAlchemy 작성자 Mike Bayer가 개발한 데이터베이스 마이그레이션 프레임워크입니다. ORM 모델 정의와 실제 데이터베이스 스키마 사이의 차이를 감지하여 마이그레이션 스크립트를 자동 생성하고, 이를 순차적으로 적용하거나 롤백하는 기능을 제공합니다.

핵심 역할은 다음과 같습니다:

- **스키마 버전 관리**: 각 마이그레이션 파일이 고유 리비전 ID를 가지며, 체인 형태로 변경 이력을 추적합니다.
- **자동 생성(Autogenerate)**: SQLAlchemy 모델의 `metadata`와 실제 DB 스키마를 비교하여 `upgrade()`/`downgrade()` 코드를 자동으로 생성합니다.
- **양방향 마이그레이션**: 업그레이드뿐 아니라 다운그레이드도 지원하여 안전한 롤백이 가능합니다.

---

## 2. 등장 배경 및 필요성

- **수동 SQL 관리의 한계**: 테이블 구조가 변경될 때마다 직접 `ALTER TABLE` 문을 작성하고 실행하는 방식은 휴먼 에러에 취약하며, 환경별 스키마 불일치를 유발합니다.
- **팀 협업 시 충돌**: 여러 개발자가 동시에 스키마를 변경하면, 어떤 변경이 먼저 적용되어야 하는지 추적하기 어렵습니다.
- **환경 간 일관성**: 개발, 스테이징, 프로덕션 환경에서 동일한 스키마를 보장해야 하며, 이를 코드 기반으로 관리할 필요가 있습니다.
- **ORM과의 정합성**: SQLAlchemy 모델을 수정했을 때 DB에 반영하는 과정이 자동화되지 않으면, 모델과 스키마 사이의 괴리가 누적됩니다.

---

## 3. 작동 원리 / 핵심 개념

### 3.1 프로젝트 구조

Alembic 프로젝트는 다음 요소로 구성됩니다:

| 파일/디렉토리 | 역할 |
|---------------|------|
| `alembic.ini` | 전역 설정 (마이그레이션 스크립트 경로, 로깅 등) |
| `env.py` | 마이그레이션 실행 환경 설정 (DB 연결, 메타데이터 바인딩) |
| `script.py.mako` | 마이그레이션 파일 생성 템플릿 |
| `versions/` | 생성된 마이그레이션 스크립트가 저장되는 디렉토리 |

### 3.2 SQLAlchemy 메타데이터 연동

Alembic의 `--autogenerate` 기능은 SQLAlchemy의 `DeclarativeBase.metadata`를 기준으로 동작합니다. `env.py`에서 `target_metadata`를 지정하면, Alembic이 이 메타데이터와 실제 DB 스키마를 비교하여 차이를 감지합니다.

```python
# base.py
from sqlalchemy.orm import DeclarativeBase

class Base(DeclarativeBase):
    pass
```

```python
# env.py
from src.infrastructure.persistence.base import Base

target_metadata = Base.metadata
```

모든 ORM 모델이 `Base`를 상속해야 `autogenerate`가 해당 테이블을 인식합니다. 모델 파일을 새로 만들었는데 `env.py`에서 임포트하지 않으면, Alembic이 해당 테이블을 감지하지 못하는 점에 주의해야 합니다.

### 3.3 비동기 환경에서의 DB URL 변환

비동기 애플리케이션에서 `asyncpg` 드라이버를 사용하는 경우, Alembic 마이그레이션은 동기 드라이버인 `psycopg2`로 전환해야 합니다. Alembic 자체가 동기적으로 DB에 연결하기 때문입니다.

```python
# env.py 핵심 로직
db_settings = DatabaseSettings()
config.set_main_option("sqlalchemy.url", db_settings.url.replace("+asyncpg", ""))
```

이 한 줄이 `postgresql+asyncpg://...`를 `postgresql://...`으로 변환합니다. `postgresql://`은 SQLAlchemy가 기본 드라이버(`psycopg2`)를 사용하도록 지정하는 것과 동일합니다.

### 3.4 pydantic-settings 기반 환경 변수 연동

DB URL을 `alembic.ini`에 하드코딩하는 대신, `pydantic-settings`의 `BaseSettings`를 활용하여 환경 변수에서 주입합니다.

```python
# config.py
from pydantic_settings import BaseSettings

class DatabaseSettings(BaseSettings):
    url: str = "postgresql+asyncpg://localhost:5432/unlook"

    model_config = {"env_prefix": "DB_"}
```

이 설정은 `DB_URL` 환경 변수를 자동으로 읽습니다. `alembic.ini`에서는 `sqlalchemy.url`을 비워두고, `env.py`에서 `DatabaseSettings`를 통해 URL을 주입하는 방식입니다.

```ini
# alembic.ini
# DB URL은 env.py에서 shared/config.py의 DatabaseSettings로 주입합니다
# sqlalchemy.url =
```

이 패턴의 장점은 다음과 같습니다:

- 애플리케이션과 마이그레이션이 동일한 설정 소스를 사용합니다.
- `.env` 파일이나 환경 변수만 변경하면 모든 곳에 반영됩니다.
- 민감 정보가 코드에 노출되지 않습니다.

### 3.5 마이그레이션 파일 구조

자동 생성된 마이그레이션 파일은 다음과 같은 구조를 가집니다:

```python
"""add users table

Revision ID: a1b2c3d4e5f6
Revises: None
Create Date: 2026-03-22 10:00:00.000000
"""
from alembic import op
import sqlalchemy as sa

revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    """Upgrade schema."""
    op.create_table('users', ...)

def downgrade() -> None:
    """Downgrade schema."""
    op.drop_table('users')
```

`revision`과 `down_revision`이 단방향 연결 리스트를 형성하여, Alembic이 현재 DB 상태에서 목표 리비전까지 순차적으로 마이그레이션을 실행합니다.

---

## 4. 장점 및 이점

- **스키마 변경의 코드화**: SQL 문이 아닌 파이썬 코드로 스키마 변경을 관리하므로, 코드 리뷰와 버전 관리 시스템에 자연스럽게 통합됩니다.
- **자동 감지**: 모델 변경 시 `--autogenerate`로 마이그레이션 스크립트를 자동 생성할 수 있어, 수동 작성 대비 실수가 줄어듭니다.
- **환경 독립적 실행**: 동일한 마이그레이션 스크립트를 개발/스테이징/프로덕션 어디서든 실행할 수 있습니다.
- **롤백 지원**: `downgrade()` 함수를 통해 특정 리비전으로 되돌릴 수 있어, 배포 실패 시 빠른 복구가 가능합니다.
- **SQLAlchemy 생태계 통합**: SQLAlchemy의 타입 시스템, 방언(Dialect) 지원을 그대로 활용합니다.

---

## 5. 한계점 및 고려사항

- **감지 불가 항목**: `autogenerate`는 테이블/칼럼의 추가/삭제/타입 변경은 잘 감지하지만, 칼럼명 변경, 제약조건 이름 변경 등은 자동 감지하지 못합니다. 이 경우 수동으로 마이그레이션 코드를 작성해야 합니다.
- **데이터 마이그레이션 미지원**: 스키마 변경만 다루며, 기존 데이터의 변환(예: 칼럼 분리, 값 매핑)은 별도로 처리해야 합니다.
- **비동기 드라이버 비호환**: Alembic은 동기 엔진만 지원하므로, 비동기 프로젝트에서는 드라이버 변환 로직이 필수입니다.
- **팀 협업 시 충돌**: 여러 개발자가 동시에 마이그레이션을 생성하면, `down_revision` 체인이 충돌할 수 있습니다. `alembic merge`로 해결하거나, 작업 전 최신 마이그레이션을 먼저 반영해야 합니다.
- **자동 생성 결과 검증 필수**: `autogenerate`가 생성한 코드를 반드시 직접 확인해야 합니다. 불필요한 변경이 포함되거나, 의도한 변경이 누락될 수 있습니다.

---

## 6. 실무 적용 가이드

### 6.1 초기 설정

Alembic을 프로젝트에 도입하는 절차는 다음과 같습니다:

```bash
# 1. Alembic 초기화 (프로젝트 루트에서 실행)
alembic init src/infrastructure/persistence/migrations

# 2. alembic.ini에서 script_location 설정
# script_location = %(here)s/src/infrastructure/persistence/migrations

# 3. env.py에서 메타데이터 및 DB URL 연결 설정
# 4. alembic.ini의 sqlalchemy.url을 주석 처리 (env.py에서 주입)
```

### 6.2 마이그레이션 워크플로우

일상적인 마이그레이션 작업 흐름은 다음과 같습니다:

```bash
# 1. ORM 모델 수정 후 마이그레이션 파일 자동 생성
make migration msg="add users table"
# 내부: alembic revision --autogenerate -m "add users table"

# 2. 생성된 마이그레이션 파일을 확인하고 필요시 수정

# 3. 마이그레이션 적용
make migrate
# 내부: alembic upgrade head

# 4. 상태 확인
alembic current    # 현재 리비전 확인
alembic history    # 마이그레이션 이력 조회
```

### 6.3 Makefile 통합

반복적인 명령어를 Makefile로 추상화하면 팀 전체가 일관된 워크플로우를 따를 수 있습니다.

```makefile
migrate:
	cd api && uv run alembic upgrade head

migration:
	cd api && uv run alembic revision --autogenerate -m "$(msg)"
```

`make migration msg="설명"` 형태로 호출하면 메시지를 인자로 전달할 수 있습니다.

### 6.4 하드코딩 DB URL 제거 패턴

실무에서 흔히 발생하는 실수는 `alembic.ini`에 DB URL을 직접 기입하는 것입니다. 이를 방지하는 패턴은 다음과 같습니다:

1. `alembic.ini`의 `sqlalchemy.url`을 주석 처리합니다.
2. `env.py`에서 `pydantic-settings` 기반 설정 클래스를 임포트합니다.
3. `config.set_main_option()`으로 런타임에 URL을 주입합니다.

```python
# env.py
from src.shared.config import DatabaseSettings

db_settings = DatabaseSettings()
config.set_main_option("sqlalchemy.url", db_settings.url.replace("+asyncpg", ""))
```

이 방식을 적용하면 `.env` 파일에 `DB_URL=postgresql+asyncpg://user:pass@host:5432/dbname`만 설정해 두면, 애플리케이션 런타임과 마이그레이션 실행이 모두 동일한 설정을 참조합니다.

### 6.5 주의사항 체크리스트

- 새 ORM 모델을 작성한 후, `env.py`에서 해당 모델이 임포트되는지 확인합니다.
- `autogenerate`로 생성된 파일은 반드시 리뷰한 후 커밋합니다.
- 프로덕션 배포 전 스테이징 환경에서 마이그레이션을 먼저 실행하여 검증합니다.
- `downgrade()` 함수가 올바르게 작성되었는지 확인하여 롤백 가능성을 보장합니다.
- 마이그레이션 파일은 한 번 커밋 후 수정하지 않습니다. 문제가 있으면 새 마이그레이션으로 수정합니다.

---

## 관련 문서

- [[PostgreSQL 내부 구조와 성능 최적화]] - Alembic이 관리하는 대상 데이터베이스의 내부 구조와 성능 튜닝

---

## 참고 자료

- [Alembic 공식 문서](https://alembic.sqlalchemy.org/) - 전체 기능 레퍼런스
- [SQLAlchemy 공식 문서](https://docs.sqlalchemy.org/) - ORM 메타데이터 및 엔진 설정
- [pydantic-settings 문서](https://docs.pydantic.dev/latest/concepts/pydantic_settings/) - 환경 변수 기반 설정 관리

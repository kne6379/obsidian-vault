---
created: 2026-03-14
updated: 2026-03-14
tags: [concept, backend, database]
status: done
---

# PostgreSQL 내부 구조와 성능 최적화

> MVCC 기반 동시성 제어, 실행 계획 분석, 인덱싱 전략, 파티셔닝, 운영 튜닝까지 PostgreSQL의 내부 동작 원리와 성능 최적화 기법을 다룹니다.

---

## 1. 정의

PostgreSQL 내부 구조와 성능 최적화는 기본적인 SQL 문법과 CRUD 연산을 넘어, PostgreSQL이 쿼리를 어떻게 처리하고, 트랜잭션을 어떻게 관리하며, 대규모 데이터를 어떻게 다루는지를 이해하는 영역입니다.

백엔드 시니어 엔지니어에게 요구되는 데이터베이스 역량은 단순히 "쿼리를 작성할 수 있는가"가 아니라 "왜 이 쿼리가 느린지 설명하고 최적화할 수 있는가"에 있습니다.

---

## 2. 등장 배경 및 필요성

- **성능 병목의 대부분은 DB에서 발생합니다**: 애플리케이션 성능 문제의 80% 이상이 비효율적인 쿼리, 부적절한 인덱스, 잘못된 스키마 설계에서 비롯됩니다.
- **규모가 커지면 기본 지식으로는 한계가 있습니다**: 수백만~수억 행의 테이블을 다루려면 파티셔닝, 인덱스 전략, 커넥션 관리 등 심화 지식이 필수입니다.
- **면접에서 차별화 요소입니다**: 시니어 백엔드 면접에서 "슬로우 쿼리를 어떻게 분석하고 해결했는가"는 단골 질문입니다.

---

## 3. 작동 원리 / 핵심 개념

PostgreSQL 내부 구조와 성능 최적화에 필요한 주제를 5개 영역으로 분류합니다.

### 3.1 인덱싱 전략

데이터베이스 성능 최적화의 핵심입니다.

**인덱스 유형:**

| 유형 | 용도 | 사용 시점 |
|------|------|----------|
| B-Tree | 기본 인덱스. 등호, 범위, 정렬 연산 | 대부분의 경우 기본 선택 |
| Hash | 등호 비교 전용 | 정확히 `=` 연산만 사용하는 경우 |
| GIN (Generalized Inverted) | 배열, JSONB, 전문 검색 | `@>`, `?`, `@@` 연산자 사용 시 |
| GiST (Generalized Search Tree) | 기하학적 데이터, 범위 타입 | 공간 데이터, 범위 쿼리 |
| BRIN (Block Range) | 물리적으로 정렬된 대용량 데이터 | 시계열 데이터, 로그 테이블 |

**심화 인덱스 기법:**

- **복합 인덱스(Composite Index)**: 여러 컬럼을 하나의 인덱스로 묶습니다. 컬럼 순서가 성능에 직접적 영향을 미칩니다. 선택도(Selectivity)가 높은 컬럼을 앞에 배치합니다.
- **부분 인덱스(Partial Index)**: `WHERE` 조건을 붙여 특정 행만 인덱싱합니다. 인덱스 크기를 줄이고 쓰기 성능을 유지할 수 있습니다.
- **커버링 인덱스(Covering Index)**: `INCLUDE` 절로 인덱스에 추가 컬럼을 포함합니다. 인덱스만으로 쿼리를 해결하는 Index-Only Scan이 가능합니다.
- **표현식 인덱스(Expression Index)**: `LOWER(email)`, `date_trunc('day', created_at)` 등 함수 결과를 인덱싱합니다.

**인덱스 관리:**

- `pg_stat_user_indexes` 뷰로 인덱스 사용 빈도를 모니터링합니다.
- 사용되지 않는 인덱스는 쓰기 성능을 저하시키므로 정기적으로 정리합니다.
- `REINDEX`로 비대해진 인덱스를 재구축합니다.
- `CREATE INDEX CONCURRENTLY`로 운영 중 락 없이 인덱스를 생성합니다.

### 3.2 쿼리 최적화와 실행 계획

쿼리가 내부적으로 어떻게 실행되는지 이해하고, 병목을 찾아 개선하는 영역입니다.

**EXPLAIN ANALYZE:**

PostgreSQL 쿼리 최적화의 시작점입니다. 실행 계획을 읽는 능력이 핵심입니다.

- **Seq Scan**: 전체 테이블 순차 스캔. 소규모 테이블에서는 정상이나, 대형 테이블에서 나타나면 인덱스 부재를 의심합니다.
- **Index Scan**: 인덱스를 통해 행을 찾고 테이블에서 데이터를 가져옵니다.
- **Index Only Scan**: 인덱스만으로 결과를 반환합니다. 가장 효율적입니다.
- **Bitmap Index Scan**: 여러 인덱스 조건을 결합할 때 사용됩니다.
- **Nested Loop / Hash Join / Merge Join**: 조인 전략. 데이터 크기와 정렬 여부에 따라 플래너가 선택합니다.

**주요 분석 포인트:**

- `actual time`과 `estimated rows` vs `actual rows`의 차이 → 통계 정보 갱신 필요 여부 판단
- `Buffers: shared hit/read` → 캐시 히트율 확인
- `Sort Method: external merge` → 메모리 부족으로 디스크 정렬 발생

**쿼리 최적화 기법:**

- 서브쿼리를 JOIN 또는 CTE로 변환합니다.
- `SELECT *` 대신 필요한 컬럼만 선택합니다.
- `LIMIT`/`OFFSET` 대신 커서 기반 페이지네이션(Keyset Pagination)을 사용합니다.
- 불필요한 `DISTINCT`, `ORDER BY`를 제거합니다.
- `EXISTS`가 `IN`보다 대부분 효율적입니다.

**통계 관리:**

- `ANALYZE` 명령으로 테이블 통계를 갱신합니다.
- `default_statistics_target`을 조정하여 통계 정밀도를 높입니다.
- 데이터 분포가 편향된 컬럼은 `ALTER COLUMN SET STATISTICS`로 개별 설정합니다.

### 3.3 파티셔닝

대용량 테이블을 논리적으로 분할하여 쿼리 성능과 관리 효율을 높이는 기법입니다.

**파티셔닝 방식:**

| 방식 | 분할 기준 | 적합한 경우 |
|------|----------|------------|
| Range | 값의 범위 (날짜, 숫자) | 시계열 데이터, 로그 |
| List | 지정된 값 목록 | 지역, 카테고리, 상태 |
| Hash | 해시 값 기반 균등 분배 | 고르게 분산이 필요한 경우 |

**핵심 개념:**

- **파티션 프루닝(Partition Pruning)**: 쿼리 조건에 맞는 파티션만 스캔합니다. `WHERE` 절에 파티션 키를 반드시 포함해야 효과가 있습니다.
- **파티션 단위 관리**: 오래된 파티션은 `DETACH`로 분리하고 `DROP`합니다. 대량 삭제 대비 극적으로 빠릅니다.
- **하위 파티셔닝**: 파티션을 다시 파티셔닝할 수 있습니다 (예: 연도별 → 월별).

**도입 판단 기준:**

- 테이블 크기가 수천만 행을 초과할 때
- 특정 범위의 데이터만 주로 조회할 때
- 오래된 데이터를 주기적으로 삭제해야 할 때
- 일반적으로 100만 행 이하의 테이블은 파티셔닝보다 인덱스 최적화가 효과적입니다.

### 3.4 동시성 제어와 락

다중 트랜잭션 환경에서 데이터 정합성을 유지하는 메커니즘입니다.

**MVCC (Multi-Version Concurrency Control):**

PostgreSQL의 동시성 제어 핵심입니다. 각 트랜잭션이 데이터의 스냅샷을 보며, 읽기가 쓰기를 차단하지 않습니다.

- 각 행에 `xmin`(생성 트랜잭션 ID)과 `xmax`(삭제 트랜잭션 ID)가 기록됩니다.
- `UPDATE`는 내부적으로 기존 행을 삭제 표시하고 새 행을 삽입합니다.
- 이로 인해 테이블이 비대해지며(Dead Tuple), `VACUUM`으로 정리해야 합니다.

**트랜잭션 격리 수준:**

| 수준 | Dirty Read | Non-Repeatable Read | Phantom Read | 사용 시점 |
|------|-----------|-------------------|-------------|----------|
| Read Committed (기본) | 방지 | 가능 | 가능 | 대부분의 경우 |
| Repeatable Read | 방지 | 방지 | 방지 | 일관된 읽기가 필요할 때 |
| Serializable | 방지 | 방지 | 방지 | 완벽한 정합성이 필요할 때 |

**락 유형과 데드락:**

- **Row-Level Lock**: `SELECT ... FOR UPDATE`, `FOR SHARE`
- **Table-Level Lock**: DDL 작업 시 자동 획득
- **Advisory Lock**: 애플리케이션 레벨 락. 분산 환경에서의 동시성 제어에 유용합니다.
- 데드락은 PostgreSQL이 자동 감지하고 한쪽 트랜잭션을 취소합니다. `log_lock_waits`를 활성화하여 모니터링합니다.

**VACUUM과 Autovacuum:**

- `VACUUM`: Dead Tuple을 정리하고 공간을 재활용합니다.
- `VACUUM FULL`: 테이블을 완전히 재작성합니다. 운영 중에는 테이블 락이 걸리므로 주의가 필요합니다.
- `Autovacuum`: 자동으로 VACUUM을 실행합니다. 기본 설정은 대부분의 경우 적절하지만, 쓰기가 많은 테이블은 튜닝이 필요합니다.
  - `autovacuum_vacuum_scale_factor`: Dead Tuple 비율 임계값 (기본 0.2)
  - `autovacuum_vacuum_cost_delay`: VACUUM 속도 조절 (기본 2ms)

### 3.5 운영과 모니터링

프로덕션 환경에서 안정적으로 PostgreSQL을 운영하기 위한 지식입니다.

**커넥션 관리:**

- PostgreSQL은 커넥션당 프로세스를 생성하므로, 커넥션 수가 성능에 직접 영향을 미칩니다.
- `max_connections` 설정보다 **커넥션 풀러(PgBouncer, PgPool-II)**를 사용하는 것이 표준입니다.
- `pg_stat_activity`로 현재 활성 커넥션과 대기 중인 쿼리를 모니터링합니다.
- 장시간 실행되는 쿼리는 `statement_timeout`으로 제한합니다.

**복제(Replication):**

| 방식 | 특성 | 용도 |
|------|------|------|
| 스트리밍 복제 (Streaming) | WAL 로그 기반 물리적 복제, 비동기/동기 선택 | 읽기 분산, 고가용성 |
| 논리적 복제 (Logical) | 특정 테이블만 선택적 복제 | 부분 복제, 버전 간 마이그레이션 |

**백업 전략:**

- `pg_dump`: 논리적 백업. 소규모 DB에 적합합니다.
- `pg_basebackup`: 물리적 백업. WAL 아카이빙과 결합하여 PITR(Point-In-Time Recovery)을 구현합니다.
- 운영 환경에서는 `pgBackRest` 또는 `Barman` 같은 전용 백업 도구를 사용합니다.

**핵심 메모리 설정:**

| 설정 | 역할 | 권장 값 |
|------|------|---------|
| `shared_buffers` | 공유 메모리 캐시 | 전체 RAM의 25% |
| `work_mem` | 정렬/해시 연산용 메모리 | 64MB~256MB (쿼리당) |
| `effective_cache_size` | OS 캐시 포함 추정치 | 전체 RAM의 75% |
| `maintenance_work_mem` | VACUUM, CREATE INDEX용 | 512MB~1GB |
| `wal_buffers` | WAL 쓰기 버퍼 | 64MB |

**모니터링 필수 뷰:**

- `pg_stat_user_tables`: 테이블별 읽기/쓰기 통계, Dead Tuple 수
- `pg_stat_user_indexes`: 인덱스 사용 빈도
- `pg_stat_activity`: 현재 실행 중인 쿼리와 상태
- `pg_stat_bgwriter`: 체크포인트와 버퍼 쓰기 통계
- `pg_locks`: 현재 락 상태

---

## 4. 학습 로드맵

단계별로 학습 우선순위를 정리합니다.

| 단계 | 주제 | 핵심 역량 |
|------|------|----------|
| 1단계 | EXPLAIN ANALYZE 읽기 | 실행 계획을 보고 병목을 찾을 수 있습니다 |
| 2단계 | 인덱스 전략 | 상황에 맞는 인덱스를 설계하고 불필요한 인덱스를 정리할 수 있습니다 |
| 3단계 | MVCC와 VACUUM | 트랜잭션 동작 원리를 이해하고 Dead Tuple 문제를 해결할 수 있습니다 |
| 4단계 | 파티셔닝 | 대용량 테이블의 성능 문제를 파티셔닝으로 해결할 수 있습니다 |
| 5단계 | 복제와 고가용성 | 읽기 분산과 장애 대응 아키텍처를 설계할 수 있습니다 |
| 6단계 | 성능 튜닝 | 메모리, 커넥션, Autovacuum 설정을 최적화할 수 있습니다 |

---

## 5. 한계점 및 고려사항

- **수평 확장의 한계**: PostgreSQL은 기본적으로 수직 확장(Scale-Up) 모델입니다. Citus 등의 확장을 사용하지 않으면 샤딩이 불가능합니다.
- **MVCC로 인한 비대화**: UPDATE/DELETE가 빈번한 테이블은 Dead Tuple 누적으로 성능이 저하됩니다. Autovacuum 튜닝이 필수입니다.
- **커넥션 모델의 비효율**: 프로세스 기반이므로 수천 개의 동시 커넥션을 직접 처리하기 어렵습니다. 커넥션 풀러가 필수입니다.
- **과도한 인덱싱의 부작용**: 인덱스가 많을수록 쓰기(INSERT/UPDATE/DELETE) 성능이 저하됩니다. 읽기/쓰기 비율을 고려한 설계가 필요합니다.

---

## 관련 문서

- [[RAG]] - 벡터 DB와 결합한 RAG 파이프라인에서 PostgreSQL + pgvector 확장을 활용할 수 있습니다
- [[Docker]] - 개발 환경에서 PostgreSQL 컨테이너 운영

---

## 참고 자료

- [PostgreSQL 공식 문서 — Indexes](https://www.postgresql.org/docs/current/indexes.html) - 인덱스 유형별 상세 설명
- [PostgreSQL 공식 문서 — Performance Tips](https://www.postgresql.org/docs/current/performance-tips.html) - EXPLAIN, 통계, 플래너 설정
- [PostgreSQL 공식 문서 — Table Partitioning](https://www.postgresql.org/docs/current/ddl-partitioning.html) - 파티셔닝 구현 가이드
- [Use The Index, Luke](https://use-the-index-luke.com/) - SQL 인덱싱과 쿼리 최적화 전문 가이드
- [The Internals of PostgreSQL](https://www.interdb.jp/pg/) - PostgreSQL 내부 구조 심층 해설

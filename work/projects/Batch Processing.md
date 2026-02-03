---
created: 2026-02-02
updated: 2026-02-02
tags: [project, backend, api]
status: active
---

# Batch Processing - Sequence Diagram

## 전체 아키텍처 개요

```mermaid
flowchart TB
    subgraph AWS
        EB1[EventBridge Rule<br/>배치 제출 스케줄]
        EB2[EventBridge Rule<br/>폴링 스케줄]
    end

    subgraph "LLM Service (FastAPI)"
        API[API Controller]
        UC[UseCase]
        BS[BatchService]
        Parser[SharedParserService]
    end

    subgraph Infrastructure
        Provider[BatchProvider<br/>Gemini / OpenAI / Claude]
        Storage[(Supabase Storage)]
        DB[(PostgreSQL<br/>batch_requests<br/>batch_jobs<br/>batch_request_items)]
    end

    subgraph "External API"
        ExtAPI[LLM Batch API<br/>Gemini / OpenAI / Claude]
    end

    EB1 -->|POST /batch/submit| API
    EB2 -->|POST /batch/poll| API
    API --> UC --> BS
    BS --> Provider --> ExtAPI
    BS --> Storage
    BS --> DB
    UC --> Parser
```

## Phase 1 — JSONL 빌드 & 업로드

배치 요청 데이터를 Provider별 JSONL 포맷으로 변환하고 Storage에 업로드.

```mermaid
sequenceDiagram
    autonumber
    participant Client
    participant Controller as API Controller
    participant UseCase
    participant BatchSvc as BatchService
    participant Provider as BatchProvider
    participant Storage as StorageProvider
    participant DB as Repository

    Client->>Controller: POST /batch/submit (요청 데이터)
    Controller->>UseCase: batch_submit_usecase()
    UseCase->>BatchSvc: build_and_upload_jsonl(items, provider, subject_area, display_name)

    BatchSvc->>Provider: build_request_body(items)
    Provider-->>BatchSvc: JSONL string (provider별 포맷)

    BatchSvc->>Storage: upload_from_string(path, jsonl_content)
    Storage-->>BatchSvc: upload 완료

    BatchSvc->>DB: save(BatchRequests)
    DB-->>BatchSvc: BatchRequests entity

    BatchSvc->>DB: save_items(BatchRequestItems[])
    DB-->>BatchSvc: BatchRequestItems[] saved

    BatchSvc-->>UseCase: BatchRequests
```

## Phase 2 — Provider에 배치 제출

Storage에서 JSONL을 다운로드하여 Provider API에 제출하고, BatchJob 레코드 생성.

```mermaid
sequenceDiagram
    autonumber
    participant UseCase
    participant BatchSvc as BatchService
    participant Storage as StorageProvider
    participant Provider as BatchProvider
    participant ExtAPI as External API
    participant DB as Repository

    UseCase->>BatchSvc: submit_to_provider(batch_request, provider, model, llm_model_id)

    BatchSvc->>Storage: download_to_string(storage_path)
    Storage-->>BatchSvc: JSONL content

    BatchSvc->>Provider: submit_batch(BatchSubmitRequest)
    Provider->>ExtAPI: Files API — JSONL 업로드
    ExtAPI-->>Provider: file URI
    Provider->>ExtAPI: Batch Job 생성 (file URI + model)
    ExtAPI-->>Provider: batch_name + status
    Provider-->>BatchSvc: BatchSubmitResponse(batch_name, status=PENDING)

    BatchSvc->>DB: save(BatchJobs)
    DB-->>BatchSvc: BatchJobs entity (status=PENDING)

    BatchSvc-->>UseCase: BatchJobs
    UseCase-->>UseCase: 202 Accepted (job_id)
```

## Phase 3 — 상태 폴링 & 결과 다운로드

EventBridge가 주기적으로 트리거. PENDING/RUNNING 잡 상태 확인 후, COMPLETED된 잡은 자동으로 결과 다운로드.

```mermaid
sequenceDiagram
    autonumber
    participant EB as EventBridge Rule<br/>(매 10분)
    participant Controller as API Controller
    participant UseCase
    participant BatchSvc as BatchService
    participant Provider as BatchProvider
    participant ExtAPI as External API
    participant Storage as StorageProvider
    participant DB as Repository
    participant Parser as SharedParserService

    EB->>Controller: POST /batch/poll (스케줄 트리거)
    Controller->>UseCase: batch_poll_usecase()

    UseCase->>BatchSvc: poll_all_pending_jobs()
    BatchSvc->>DB: find_pending_jobs()
    DB-->>BatchSvc: list[BatchJobs] (PENDING/RUNNING)

    loop 각 Job에 대해
        BatchSvc->>Provider: get_batch_status(batch_name)
        Provider->>ExtAPI: GET batch status
        ExtAPI-->>Provider: status
        Provider-->>BatchSvc: BatchStatusResponse

        alt 상태 변경됨
            BatchSvc->>DB: update_status(job_id, new_status)
        end
    end

    BatchSvc-->>UseCase: list[BatchJobs] (업데이트된 잡 목록)

    rect rgb(255, 240, 245)
    note over UseCase,DB: COMPLETED된 잡 자동 결과 다운로드

    loop COMPLETED 상태인 각 Job에 대해
        UseCase->>BatchSvc: download_job_result(job_id)

        BatchSvc->>DB: find_by_id_with_request(job_id)
        DB-->>BatchSvc: BatchJobs (with BatchRequest)

        BatchSvc->>Provider: download_batch_result(batch_name)
        Provider->>ExtAPI: GET result file
        ExtAPI-->>Provider: raw JSONL data
        Provider-->>BatchSvc: BatchResultResponse(results[], usage)

        BatchSvc->>Storage: upload_from_string(result_path, raw_jsonl)
        Storage-->>BatchSvc: upload 완료

        BatchSvc->>DB: update_status(job_id, counts, timestamps, result_path)
        BatchSvc-->>UseCase: BatchResultResponse
    end
    end

    rect rgb(245, 240, 255)
    note over UseCase,Parser: 결과 파싱 & 검증

    loop 각 BatchResultResponse에 대해
        UseCase->>Parser: parse_batch(result)
        note right of Parser: 1. JSON 전처리 (codeblock 제거 등)<br/>2. 스키마 검증<br/>3. 성공/실패 분류
        Parser-->>UseCase: BatchValidationResponse
    end
    end
```

## EventBridge 스케줄 구성

| Rule | 스케줄 | 대상 | 설명 |
|------|--------|------|------|
| 배치 제출 | `cron(0 2 * * ? *)` | `POST /batch/submit` | 매일 새벽 2시, 문제 생성 배치 제출 |
| 폴링 | `rate(10 minutes)` | `POST /batch/poll` | PENDING/RUNNING 잡 상태 확인 + COMPLETED 결과 다운로드 |

- 스케줄 변경은 EventBridge Rule 수정으로 처리 (DB 설정 불필요)
- Rule enable/disable로 스케줄러 on/off 제어
- 폴링 Rule은 PENDING 잡이 없으면 조기 리턴 (불필요한 비용 없음)

## 상태 전이 다이어그램

```mermaid
stateDiagram-v2
    [*] --> PENDING: submit_batch()

    PENDING --> RUNNING: Provider 처리 시작
    PENDING --> FAILED: 제출 오류

    RUNNING --> COMPLETED: 처리 완료
    RUNNING --> FAILED: 처리 실패
    RUNNING --> CANCELLED: 취소 요청

    COMPLETED --> [*]: download_result()
    FAILED --> [*]
    CANCELLED --> [*]
```

### Provider별 상태 매핑 (Gemini)

| Gemini API | Internal Status |
|------------|-----------------|
| `JOB_STATE_PENDING` | PENDING |
| `JOB_STATE_RUNNING` | RUNNING |
| `JOB_STATE_SUCCEEDED` | COMPLETED |
| `JOB_STATE_FAILED` | FAILED |
| `JOB_STATE_CANCELLED` | FAILED |
| `JOB_STATE_EXPIRED` | FAILED |

## DB 테이블 관계

```mermaid
erDiagram
    BatchRequests ||--o{ BatchJobs : "1:N"
    BatchRequests ||--o{ BatchRequestItems : "1:N"
    BatchJobs }o--|| LlmModels : "N:1"

    BatchRequests {
        uuid id PK
        string display_name
        string storage_path
        string subject_area
        int request_count
    }

    BatchJobs {
        uuid id PK
        uuid batch_request_id FK
        string batch_name "Provider 발급 ID"
        enum provider "gemini | openai | claude"
        enum status "PENDING | RUNNING | COMPLETED | FAILED | CANCELLED"
        string model
        uuid llm_model_id FK
        int success_count
        int fail_count
        string result_storage_path
        int input_tokens
        int output_tokens
        decimal cost
    }

    BatchRequestItems {
        uuid id PK
        uuid batch_request_id FK
        string key "UQ — 결과 매칭 키"
        uuid question_type_id
        uuid subject_id
        uuid keyword_id
        uuid prompt_id
        string grade
    }
```

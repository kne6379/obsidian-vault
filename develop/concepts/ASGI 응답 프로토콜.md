---
created: 2026-02-20
updated: 2026-02-20
tags: [concept, backend, api]
status: done
---

# ASGI 응답 프로토콜

> ASGI에서 HTTP 응답은 시작(start)과 본문(body) 두 단계로 분리되어 전송되며, 이 구조가 미들웨어의 예외 처리 설계에 직접적인 제약을 부여합니다.

---

## 1. 정의

ASGI(Asynchronous Server Gateway Interface)는 파이썬 비동기 웹 애플리케이션과 서버 간의 표준 인터페이스입니다. HTTP 응답 프로토콜은 이 인터페이스에서 응답을 클라이언트에게 전달하는 메시지 규약을 의미합니다.

ASGI의 핵심 설계 원칙은 응답을 **단일 객체가 아닌 메시지 스트림**으로 취급하는 것입니다. 응답은 `send` 콜러블을 통해 순차적으로 전송되며, 각 메시지는 명확한 타입과 역할을 가집니다.

---

## 2. 등장 배경 및 필요성

### WSGI의 한계

기존 WSGI는 응답을 동기적으로 한 번에 반환하는 구조였습니다. 이 방식은 스트리밍 응답, 웹소켓, 서버 전송 이벤트(SSE) 등 비동기 패턴을 지원하기 어려웠습니다.

### 비동기 스트리밍 요구

대용량 파일 전송이나 실시간 데이터 스트리밍에서는 응답 본문을 여러 청크로 나누어 전송해야 합니다. 이를 위해 상태 코드/헤더 전송과 본문 전송을 분리하는 설계가 필요했습니다.

### 미들웨어 제어 필요

응답을 단계별로 분리함으로써 미들웨어가 상태 코드나 헤더를 가로채어 수정하거나, 본문 전송 과정을 감시하는 것이 가능해집니다.

---

## 3. 작동 원리 / 핵심 개념

### 3.1 2단계 응답 전송

ASGI HTTP 응답은 반드시 두 종류의 메시지를 순서대로 전송합니다.

**1단계: `http.response.start`**

상태 코드와 헤더를 전송합니다. 요청당 정확히 한 번만 허용됩니다.

```python
await send({
    "type": "http.response.start",
    "status": 200,
    "headers": [
        [b"content-type", b"application/json"],
    ],
})
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `type` | 문자열 | `"http.response.start"` 고정 |
| `status` | 정수 | HTTP 상태 코드 |
| `headers` | 바이트 쌍 리스트 | `[이름, 값]` 쌍의 목록 |

**2단계: `http.response.body`**

응답 본문을 전송합니다. `more_body` 플래그로 추가 전송 여부를 지정합니다.

```python
await send({
    "type": "http.response.body",
    "body": b'{"message": "ok"}',
    "more_body": False,
})
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `type` | 문자열 | `"http.response.body"` 고정 |
| `body` | 바이트 문자열 | 응답 본문 데이터 |
| `more_body` | 불리언 | `False`이면 응답 완료 (기본값: `False`) |

### 3.2 단일 start 규칙

`http.response.start`는 요청당 한 번만 전송할 수 있습니다. 두 번째 시도 시 ASGI 서버(uvicorn 등)가 `RuntimeError`를 발생시킵니다. 이 규칙은 HTTP 프로토콜 자체의 제약에서 비롯됩니다. 상태 코드와 헤더는 본문보다 먼저, 그리고 한 번만 전송되어야 합니다.

### 3.3 미들웨어에서의 중복 응답 문제

예외 처리 미들웨어에서 이 규칙이 실질적 문제가 됩니다. 발생 시나리오는 다음과 같습니다.

1. 정상 처리 흐름에서 `http.response.start` 전송 완료 (200 OK + 헤더)
2. `http.response.body` 전송 중 예외 발생
3. `except` 블록에서 새로운 JSON 응답 생성 시도
4. 새 응답도 `http.response.start`를 전송하려 함
5. start가 두 번 전송 → `RuntimeError` 발생

```
정상 흐름:   start(200) → body 전송 중 예외 발생
                                    ↓
except 블록: start(500) 시도 → RuntimeError (start 중복)
```

### 3.4 send_wrapper 패턴

이 문제의 해결책은 `send` 콜러블을 클로저로 감싸서 응답 시작 여부를 추적하는 것입니다.

```python
async def __call__(self, scope, receive, send):
    if scope["type"] != "http":
        await self.app(scope, receive, send)
        return

    response_started = False

    async def send_wrapper(message):
        nonlocal response_started
        if message["type"] == "http.response.start":
            response_started = True
        await send(message)

    try:
        await self.app(scope, receive, send_wrapper)
    except Exception as exc:
        if response_started:
            # start 이후 예외: 새 응답 불가, 로그만 남기고 재발생
            logger.error(f"Exception after response started: {exc}")
            raise
        # start 이전 예외: 정상적으로 500 응답 전송 가능
        response = JSONResponse(
            status_code=500,
            content={"detail": "Internal Server Error"},
        )
        await response(scope, receive, send)
```

이 패턴의 핵심 설계 결정을 정리하면 다음과 같습니다.

| 항목 | 설명 |
|------|------|
| `send_wrapper`가 `async`인 이유 | 원본 `send`가 코루틴이므로 `await` 필요 |
| `body` 전송 여부를 추적하지 않는 이유 | `start`만 전송되면 이미 두 번째 응답 불가 |
| `response_started` 초기화 시점 | 각 요청마다 `__call__`이 새로 호출되므로 자동 초기화 |
| 방어 코드 비용 | 클로저 + `bool` 변수 하나로 무시할 수 있는 수준 |

---

## 4. 장점 및 이점

- **스트리밍 지원**: 응답을 분리함으로써 대용량 데이터를 청크 단위로 전송할 수 있습니다.
- **미들웨어 유연성**: 미들웨어가 `send`를 래핑하여 응답을 가로채거나 수정할 수 있습니다.
- **프로토콜 안전성**: 단일 start 규칙이 서버 수준에서 강제되어 잘못된 응답 전송을 방지합니다.
- **비동기 호환**: `send`가 코루틴이므로 논블로킹 I/O와 자연스럽게 통합됩니다.

---

## 5. 한계점 및 고려사항

- **start 이후 오류 복구 불가**: `http.response.start`가 전송된 후에는 상태 코드를 변경하거나 새 응답을 보낼 방법이 없습니다. 클라이언트는 불완전한 응답을 받게 됩니다.
- **미들웨어 작성 난이도**: 순수 ASGI 미들웨어를 올바르게 작성하려면 메시지 흐름과 프로토콜 규칙을 정확히 이해해야 합니다. Starlette의 `BaseHTTPMiddleware`가 이를 추상화하지만 성능 오버헤드가 있습니다.
- **디버깅 어려움**: 중복 start로 인한 `RuntimeError`는 원래 예외를 덮어쓸 수 있어 근본 원인 파악이 어려워집니다. send_wrapper 패턴에서 원래 예외를 로깅하는 것이 중요합니다.

---

## 6. 실무 적용 가이드

### 6.1 예외 처리 미들웨어 작성 시 체크리스트

1. `response_started` 플래그로 응답 시작 여부를 반드시 추적합니다.
2. start 이후 예외 발생 시 새 응답을 시도하지 않고 로그를 남긴 뒤 예외를 재발생시킵니다.
3. start 이전 예외 발생 시에만 커스텀 오류 응답을 전송합니다.

### 6.2 send_wrapper 작성 시 주의사항

- `send_wrapper`는 반드시 `async`로 선언합니다.
- `nonlocal` 키워드로 외부 스코프의 플래그를 참조합니다.
- HTTP가 아닌 스코프(`websocket`, `lifespan`)는 조기 반환하여 불필요한 래핑을 방지합니다.

---

## 관련 문서

- [[멱등성]] - 분산 시스템에서의 안전한 재시도 설계
- [[디자인 패턴 비교]] - Strategy, Provider 등 미들웨어와 유사한 구조적 패턴

---

## 참고 자료

- [ASGI HTTP & WebSocket Message Format](https://asgi.readthedocs.io/en/latest/specs/www.html) - ASGI 공식 명세
- [ASGI Specification](https://asgi.readthedocs.io/en/latest/specs/main.html) - ASGI 메인 명세
- [Starlette Middleware](https://www.starlette.io/middleware/) - Starlette 미들웨어 문서
- [FastAPI Advanced Middleware](https://fastapi.tiangolo.com/advanced/middleware/) - FastAPI 미들웨어 가이드

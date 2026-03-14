---
created: 2026-03-13
updated: 2026-03-13
tags: [reference, tools, terminal]
status: done
---

# Ghostty 단축키

> Ghostty 터미널 에뮬레이터의 macOS 기본 단축키 레퍼런스입니다.

---

## 1. 탭 관리

| 단축키                   | 동작                |
| --------------------- | ----------------- |
| `Cmd + T`             | 새 탭               |
| `Cmd + W`             | 현재 서피스(탭/분할/창) 닫기 |
| `Cmd + Alt + W`       | 현재 탭 닫기           |
| `Cmd + Shift + [`     | 이전 탭              |
| `Cmd + Shift + ]`     | 다음 탭              |
| `Ctrl + Shift + Tab`  | 이전 탭 (대체)         |
| `Ctrl + Tab`          | 다음 탭 (대체)         |
| `Cmd + 1` ~ `Cmd + 8` | 탭 1~8로 이동         |
| `Cmd + 9`             | 마지막 탭으로 이동        |

---

## 2. 분할 창 관리

| 단축키                    | 동작                 |
| ---------------------- | ------------------ |
| `Cmd + D`              | 오른쪽으로 분할           |
| `Cmd + Shift + D`      | 아래로 분할             |
| `Cmd + [`              | 이전 분할 창으로 포커스      |
| `Cmd + ]`              | 다음 분할 창으로 포커스      |
| `Cmd + Alt + ↑/↓/←/→`  | 해당 방향의 분할 창으로 포커스  |
| `Cmd + Ctrl + ↑/↓/←/→` | 해당 방향으로 분할 창 크기 조정 |
| `Cmd + Ctrl + =`       | 모든 분할 창 크기 균등화     |
| `Cmd + Shift + Enter`  | 현재 분할 창 확대/복원 토글   |

---

## 3. 창 관리

| 단축키 | 동작 |
|--------|------|
| `Cmd + N` | 새 창 |
| `Cmd + Shift + W` | 창 닫기 |
| `Cmd + Alt + Shift + W` | 모든 창 닫기 |
| `Cmd + Enter` | 전체 화면 토글 |
| `Cmd + Q` | 애플리케이션 종료 |

---

## 4. 클립보드

| 단축키 | 동작 |
|--------|------|
| `Cmd + C` | 복사 (선택 영역이 없으면 `Ctrl+C` 전송) |
| `Cmd + V` | 붙여넣기 |
| `Cmd + Shift + V` | 선택 클립보드에서 붙여넣기 |

---

## 5. 검색

| 단축키 | 동작 |
|--------|------|
| `Cmd + F` | 검색 열기 |
| `Cmd + E` | 현재 선택 영역 검색 |
| `Cmd + G` | 다음 검색 결과 |
| `Cmd + Shift + G` | 이전 검색 결과 |
| `Cmd + Shift + F` | 검색 닫기 |
| `Escape` | 검색 닫기 (대체) |

---

## 6. 텍스트 선택

| 단축키 | 동작 |
|--------|------|
| `Cmd + A` | 전체 선택 |
| `Shift + ←/→/↑/↓` | 선택 영역 조정 |
| `Shift + Page Up/Down` | 페이지 단위 선택 영역 조정 |
| `Shift + Home/End` | 처음/끝까지 선택 |

---

## 7. 스크롤 및 탐색

| 단축키 | 동작 |
|--------|------|
| `Cmd + Home` | 스크롤백 최상단으로 |
| `Cmd + End` | 최하단으로 |
| `Cmd + Page Up` | 한 페이지 위로 |
| `Cmd + Page Down` | 한 페이지 아래로 |
| `Cmd + J` | 현재 선택 영역으로 스크롤 |
| `Cmd + ↑` | 이전 셸 프롬프트로 이동 * |
| `Cmd + ↓` | 다음 셸 프롬프트로 이동 * |

\* 셸 통합(Shell Integration) 설정이 필요합니다.

---

## 8. 줄 편집 (Emacs 스타일)

셸에 원시 제어 문자를 전송하는 단축키입니다.

| 단축키 | 동작 | 전송 시퀀스 |
|--------|------|------------|
| `Cmd + →` | 줄 끝으로 이동 | `Ctrl+E` |
| `Cmd + ←` | 줄 처음으로 이동 | `Ctrl+A` |
| `Cmd + Backspace` | 줄 처음까지 삭제 | `Ctrl+U` |
| `Alt + ←` | 한 단어 뒤로 이동 | `ESC b` |
| `Alt + →` | 한 단어 앞으로 이동 | `ESC f` |

---

## 9. 글꼴 크기

| 단축키 | 동작 |
|--------|------|
| `Cmd + =` | 글꼴 크기 1pt 증가 |
| `Cmd + -` | 글꼴 크기 1pt 감소 |
| `Cmd + 0` | 글꼴 크기 기본값 복원 |

---

## 10. 실행 취소 및 화면 관리

| 단축키 | 동작 |
|--------|------|
| `Cmd + Z` | 실행 취소 (창/탭/분할 생성·닫기 되돌리기) |
| `Cmd + Shift + Z` | 다시 실행 |
| `Cmd + K` | 화면 및 스크롤백 초기화 |

---

## 11. 설정 및 도구

| 단축키 | 동작 |
|--------|------|
| `Cmd + ,` | 설정 파일 열기 |
| `Cmd + Shift + ,` | 설정 파일 다시 불러오기 |
| `Cmd + Alt + I` | 터미널 인스펙터 토글 |
| `Cmd + Shift + P` | 커맨드 팔레트 토글 |

---

## 12. 화면 내보내기

| 단축키 | 동작 |
|--------|------|
| `Cmd + Shift + J` | 화면 내용을 파일로 저장 (클립보드에 붙여넣기) |
| `Cmd + Alt + Shift + J` | 화면 내용을 파일로 저장 (기본 앱으로 열기) |
| `Cmd + Ctrl + Shift + J` | 화면 내용을 파일로 저장 (클립보드에 복사) |

---

## 13. 기본 미할당 액션

기본 단축키가 없지만 `~/.config/ghostty/config`에서 할당할 수 있는 액션입니다.

| 액션 | 설명 |
|------|------|
| `toggle_window_float_on_top` | 항상 위에 표시 |
| `toggle_secure_input` | 보안 입력 토글 |
| `toggle_mouse_reporting` | 마우스 리포팅 토글 |
| `toggle_readonly` | 읽기 전용 모드 토글 |
| `toggle_background_opacity` | 배경 투명도 토글 |
| `toggle_quick_terminal` | 퀵 터미널 토글 |
| `toggle_visibility` | 전체 창 표시/숨김 |

설정 예시:

```
keybind = ctrl+shift+f=toggle_window_float_on_top
keybind = ctrl+shift+q=toggle_quick_terminal
```

---

## 관련 문서

- (관련 문서 추가 예정)

---

## 참고 자료

- [Ghostty 공식 문서 - 키바인딩](https://ghostty.org/docs/config/keybind) - 키바인딩 설정 가이드
- [Ghostty 공식 문서 - 액션 레퍼런스](https://ghostty.org/docs/config/keybind/reference) - 전체 액션 목록

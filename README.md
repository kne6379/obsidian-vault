# Obsidian Knowledge Vault

Obsidian과 Claude를 활용하여 AI 기반으로 지식을 정리하고 관리하는 개인 문서 저장소입니다.

---

## 왜 Obsidian인가

AI 에이전트가 문서 간 그래프 연결을 활용하여 지식에 기반한 답변과 작업을 수행할 수 있도록 하기 위해 Obsidian을 사용합니다. `[[위키링크]]`로 연결된 문서들은 에이전트가 관련 컨텍스트를 탐색하고 참조하는 데 유용합니다.

---

## 구조

```
.
├── develop/          # 개발 지식
│   ├── concepts/     # 개념/이론 문서
│   ├── _meta/        # 규칙, 용어집, 인덱스
│   └── _templates/   # 문서 템플릿
```

---

## 문서 목록

- [develop 문서 목록](develop/_meta/INDEX.md)

---

## 작성 규칙

- 문체: `~입니다/~합니다` 체
- 링크: Obsidian 위키링크 `[[문서명]]` 사용
- 프론트매터: `created`, `updated`, `tags`, `status` 필수

상세 규칙은 각 폴더의 `_meta/RULES.md` 참조.

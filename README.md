# Obsidian Knowledge Vault

Obsidian과 Claude를 활용하여 AI 기반으로 지식을 정리하고 관리하는 개인 문서 저장소입니다. 문서 간 그래프 연결을 통해 AI 에이전트가 지식에 기반한 답변과 작업을 수행할 수 있도록 합니다.

---

## 구조

```
.
├── knowledge/        # 개발 지식 (공개)
│   ├── concepts/     # 개념/이론 문서
│   ├── references/   # 참고 자료
│   ├── _meta/        # 용어집, 인덱스
│   └── _templates/   # 문서 템플릿
├── ventures/         # 사업 기획 (공개)
│   ├── brainstorms/  # 브레인스토밍
│   ├── projects/     # 사업 프로젝트
│   ├── _meta/
│   └── _templates/
├── scripts/          # 자동화 스크립트
└── _meta/            # 볼트 전체 분석
```

> `projects/`(회사 프로젝트)와 `life/`(개인)는 비공개 영역으로 이 저장소에 포함되지 않습니다.

---

## 문서 목록

- [knowledge 문서 목록](knowledge/_meta/INDEX.md)
- [ventures 문서 목록](ventures/_meta/INDEX.md)

---

## 작성 규칙

- 문체: `~입니다/~합니다` 체
- 링크: Obsidian 위키링크 `[[문서명]]` 사용
- 프론트매터: `created`, `updated`, `tags`, `status` 필수

상세 규칙은 `.claude/rules/` 하위 영역별 규칙 파일을 참조합니다.

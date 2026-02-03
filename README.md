# Obsidian Knowledge Vault

개인 지식 관리를 위한 Obsidian 기반 문서 저장소입니다.

---

## 구조

```
.
├── develop/          # 개발 지식
│   ├── concepts/     # 개념/이론 문서
│   ├── _meta/        # 규칙, 용어집, 인덱스
│   └── _templates/   # 문서 템플릿
│
└── work/             # 업무 문서
    ├── projects/     # 프로젝트 설계/명세
    └── notes/        # 미팅/리서치 노트
```

---

## 주요 문서

### develop/concepts/

| 문서 | 설명 |
|------|------|
| Docker | 컨테이너화 플랫폼 |
| ECS | AWS 컨테이너 오케스트레이션 |
| GraphRAG | 지식 그래프 기반 RAG |
| API Gateway | MSA 단일 진입점 패턴 |
| RAG | 검색 증강 생성 |

### work/

| 문서 | 설명 |
|------|------|
| Batch Processing | 배치 처리 서비스 설계 |
| EventBridge 도입 미팅 | 스케줄링 서비스 전환 검토 |

---

## 작성 규칙

- 문체: `~입니다/~합니다` 체
- 링크: Obsidian 위키링크 `[[문서명]]` 사용
- 프론트매터: `created`, `updated`, `tags`, `status` 필수

상세 규칙은 각 폴더의 `_meta/RULES.md` 참조.

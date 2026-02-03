# develop 폴더 가이드

이 문서는 `develop` 폴더에서 작업할 때 참조하는 **영역별 지침서**입니다.
공통 규칙(문체, 용어, 프론트매터, 링크 등)은 루트 `CLAUDE.md`를 따릅니다.

---

## 이 폴더의 목적

`develop` 폴더는 **개발 분야의 지식**을 중심으로 구성되어 있습니다.

| 영역           | 주요 주제                                         |
| ------------ | --------------------------------------------- |
| **AI/데이터**   | LLM, RAG, 임베딩, 벡터 DB, 프롬프트 엔지니어링, MLOps       |
| **인프라/클라우드** | Docker, Kubernetes, AWS/GCP/Azure, CI/CD, IaC |
| **백엔드 개발**   | API 설계, 데이터베이스, 인증/보안, 마이크로서비스                |
| **프론트엔드**    | React, TypeScript, 상태관리, 성능 최적화               |

---

## 폴더 구조

```
develop/
├── CLAUDE.md            ← 현재 문서
├── _meta/               # 메타 문서
│   ├── RULES.md         # 상세 작성 규칙
│   ├── GLOSSARY.md      # 용어 정의
│   └── INDEX.md         # 전체 문서 목록
├── _templates/          # 문서 템플릿
│   └── CONCEPT.md       # 개념 문서 템플릿
├── concepts/            # 개념/이론 문서
├── tutorials/           # 실습/가이드 문서
├── troubleshooting/     # 문제 해결 기록
└── references/          # 외부 참고 자료
```

---

## 작업 전 필수 확인

1. `_meta/RULES.md` - 섹션 구조, 메타데이터 형식
2. `_meta/INDEX.md` - 전체 문서 목록 (중복 방지)
3. `_meta/GLOSSARY.md` - 용어 정의
4. `_templates/CONCEPT.md` - 개념 문서 템플릿

---

## 작업 유형별 가이드

### 새 개념 문서 작성

1. `_meta/INDEX.md`에서 유사 문서 존재 여부 확인
2. `_templates/CONCEPT.md` 템플릿 복사
3. `_meta/RULES.md`의 섹션 구조 준수
4. 관련 문서에 `[[링크]]` 연결
5. 작성 완료 후 `_meta/INDEX.md`에 문서 등록
6. 새 용어가 있으면 `_meta/GLOSSARY.md`에 추가

### 기존 문서 수정

1. 해당 문서의 `updated` 날짜 갱신
2. 수정 내용이 크면 관련 문서 링크 확인
3. 용어 변경 시 `_meta/GLOSSARY.md` 동기화

---

## 태그 체계

**유형**: `concept`, `tutorial`, `troubleshooting`, `reference`

**주제**:
- AI/데이터: `ai`, `llm`, `rag`, `embedding`, `mlops`
- 인프라: `devops`, `docker`, `k8s`, `cloud`, `cicd`
- 개발: `backend`, `frontend`, `database`, `api`, `security`

**상태**: `draft`, `review`, `done`

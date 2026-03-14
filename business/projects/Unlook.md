---
created: 2026-03-13
updated: 2026-03-13
tags: [project, ai, dating, fashion, clip]
status: idea
domain: AI 데이팅 플랫폼
---

# Unlook

> 얼굴이 아닌 스타일과 바이브로 연결되는 새로운 방식의 데이팅 플랫폼입니다.

---

## 1. 서비스 개요

얼굴 사진 없이 매칭되는 데이팅 플랫폼입니다. 유저는 온보딩에서 선호도 좌표(Preference Vector)를 생성하고, 전신 착장샷과 스타일 사진을 통해 자신의 고유 좌표(Identity Vector)를 등록합니다. 시스템은 두 좌표 간의 거리 계산으로 매칭하며, 얼굴은 매칭 성사 후에만 공개됩니다.

### 핵심 차별점

- **No Face, Style First**: 프로필에 얼굴 노출이 없습니다. 착장, 체형, 분위기 기반으로 추천합니다.
- **좌표 매칭**: 스와이프 피로 없이, 알고리즘이 호환성 높은 상대를 자동 추천합니다.
- **쌍방향 최적화**: 내가 좋아하는 스타일과 상대가 좋아하는 스타일이 서로 맞는 경우에만 매칭됩니다.

---

## 2. 유저 플로우

### Phase 1 — 온보딩 (Preference Vector 생성)

```
[스타일 이미지 선택] → [체형 선호도 슬라이더] → [패션 키워드 태깅] → 선호도 좌표 생성
```

1. **스타일 스와이프**: 전신 착장 이미지 20~30장을 좋아요/싫어요로 분류합니다.
2. **체형 선호 설정**: 키, 체형, 실루엣 등을 슬라이더로 입력합니다.
3. **패션 키워드**: 미니멀, 스트릿, 캐주얼, 포멀, 아메카지 등을 태깅합니다.
4. 이 데이터를 종합하여 **N차원 Preference Vector**를 생성합니다.

### Phase 2 — 프로필 등록 (Identity Vector 생성)

```
[전신 사진 업로드 (2~5장)] → [AI 분석] → [스타일/체형/컬러 좌표 추출] → Identity Vector 생성
```

1. **전신 착장샷 업로드**: 얼굴은 자동 블러 처리 또는 크롭합니다.
2. **AI 분석 파이프라인**:
   - 체형 추정 (키, 어깨너비, 비율 등의 정규화된 벡터)
   - 패션 스타일 분류 (FashionSigLIP으로 스타일 임베딩 추출)
   - 컬러 팔레트 분석 (착용 의류 색상 분포)
3. 이 데이터를 종합하여 **N차원 Identity Vector**를 생성합니다.

### Phase 3 — 매칭

```
User A의 Preference Vector ↔ User B의 Identity Vector
User B의 Preference Vector ↔ User A의 Identity Vector
→ 쌍방 유사도가 모두 threshold 이상일 때 매칭 풀에 진입
```

### Phase 4 — 커뮤니케이션

- 매칭 성사 시 채팅이 열립니다 (여전히 얼굴 미공개).
- 대화 N회 이상 또는 쌍방 동의 시 **얼굴 공개(Reveal)** 단계에 진입합니다.
- Reveal 이후에도 계속할지 결정합니다.

---

## 3. 좌표 시스템

### 3.1 벡터 구성

| 차원 그룹 | 세부 항목 | 추출 방식 | 차원 수 |
|-----------|-----------|-----------|---------|
| 스타일 (Fashion) | 패션 카테고리, 브랜드 톤, 핏감 | Marqo-FashionSigLIP 임베딩 | 768 |
| 체형 (Physical) | 어깨/힙 비율, 상체/하체 비율 등 | MediaPipe Pose → 비율 정규화 | ~8 |
| 컬러 (Color) | 주요 착용 컬러, 톤 (웜/쿨) | 의류 영역 K-Means 클러스터링 | ~12 |
| 무드 (Mood) | 전체적 분위기, 배경, 포즈 | FashionSigLIP text-image similarity | 768에 포함 |
| 자기기술 (Self-tag) | 유저가 직접 선택한 키워드 | 원핫 + 가중치 | ~20 |

### 3.2 매칭 스코어 계산

```
match_score(A, B) = α · cos_sim(A.pref, B.identity)
                  + β · cos_sim(B.pref, A.identity)
                  + γ · contextual_boost(A, B)
```

- `α, β`: 쌍방 가중치 (기본 0.4, 0.4)
- `γ`: 지역, 나이, 활동시간 등 컨텍스트 보정 (0.2)
- threshold 이상이면 추천 큐에 삽입하고, 스코어 높은 순으로 노출합니다.

---

## 4. ML 파이프라인

### 4.1 스타일 임베딩

**모델**: Marqo-FashionSigLIP (768차원, 현 시점 패션 임베딩 SOTA)

일반 CLIP 대비 패션 도메인에서 +57% 성능 개선을 보입니다. 색상, 소재, 핏, 슬리브 길이 등 패션 세부 속성을 구분합니다.

**처리 방식**: 전신 사진을 SCHP(Self-Correction for Human Parsing)로 의류 영역(상의, 하의, 코트, 신발 등 20개 파트)을 분리한 뒤, 각 영역을 FashionSigLIP에 넣어 임베딩을 추출합니다. 사진 여러 장의 임베딩을 평균하여 안정적인 스타일 벡터를 생성합니다.

> 초기 MVP에서는 세그멘테이션 없이 전신 사진을 통으로 FashionSigLIP에 넣는 것도 가능합니다. 품질은 떨어지지만 동작합니다.

### 4.2 체형 분석

**모델**: MediaPipe Pose (33개 3D 랜드마크)

전신 정면 사진에서 상대적 비율(어깨/힙, 상체/하체, 어깨 너비/전체 높이)을 추출합니다. 절대 치수(cm)는 기준점 없이 추출할 수 없으나, 체형 분류에는 상대 비율만으로 충분합니다. 정면 사진 기준 상관계수 약 0.91입니다.

### 4.3 컬러 분석

**도구**: OpenCV + K-Means

SCHP(또는 간이 세그멘테이션)으로 분리한 의류 영역에서 주요 색상 클러스터를 추출합니다. 웜톤/쿨톤, 주요 컬러 팔레트를 벡터화합니다.

### 4.4 얼굴 블러

**모델**: MediaPipe Face Detection

업로드 시점에 실시간으로 얼굴 영역을 감지하고 가우시안 블러를 적용합니다. 블러 처리된 버전만 저장하고, 원본은 Reveal 전용으로 암호화 저장합니다.

### 4.5 Preference Vector 생성

온보딩에서 좋아요/싫어요로 분류한 이미지들의 FashionSigLIP 임베딩을 활용합니다.

```python
pref = mean(liked_embeddings) - 0.3 * mean(disliked_embeddings)
pref = normalize(pref)
```

### 4.6 벡터 저장 및 검색

**저장소**: pgvector (Supabase 내장), halfvec 사용

| 유저 규모 | 대응 |
|-----------|------|
| ~10만 | pgvector 기본으로 충분 |
| 10만~100만 | HNSW 인덱스 (m=16, ef_construction=200) |
| 100만+ | pgvectorscale 또는 Pinecone 이관 검토 |

---

## 5. 핵심 기능 (MVP)

- 온보딩 스타일 스와이프 + Preference Vector 생성
- 전신 사진 업로드 + AI 기반 Identity Vector 생성
- 얼굴 자동 블러/크롭 처리
- 좌표 기반 매칭 추천 (일 5~10명)
- 1:1 채팅 + Reveal 기능
- 기본 프로필 (닉네임, 나이, 지역, 한줄소개)

---

## 6. 비즈니스 모델

| 티어 | 가격 | 내용 |
|------|------|------|
| Free | 0원 | 일 3명 추천, 기본 채팅 |
| Plus | 29,000원/월 | 일 15명 추천, Reveal 무제한, 스타일 리포트 |
| Unlimited | 169,000원/3개월 | 무제한 추천, 우선 노출, 상세 분석 리포트, 시즌 리프레시 |

추가 수익: 스타일 컨설팅 연계, 패션 브랜드 콜라보 (추천 착장 제안)

---

## 7. 기술 스택

### 7.1 클라이언트

| 구분 | 선택 | 이유 |
|------|------|------|
| 모바일 앱 | React Native (Expo) | iOS/Android 동시 커버, EAS로 빌드/배포 자동화 |
| 웹 (어드민/랜딩) | Next.js 14+ | 랜딩 페이지 SSR + 어드민 대시보드 |
| UI 라이브러리 | Tamagui 또는 NativeWind | RN + Web 크로스플랫폼 스타일링 |

### 7.2 백엔드

| 구분 | 선택 | 이유 |
|------|------|------|
| API 서버 | FastAPI (Python) | ML 파이프라인과 같은 언어, 비동기 지원 |
| 실시간 채팅 | Supabase Realtime 또는 Socket.IO | 채팅 + Reveal 이벤트 실시간 처리 |
| 인증 | Supabase Auth 또는 Firebase Auth | 소셜 로그인 + 전화번호 인증 |
| 태스크 큐 | Celery + Redis | 이미지 분석, 벡터 생성 등 비동기 작업 |

### 7.3 데이터베이스

| 구분 | 선택 | 이유 |
|------|------|------|
| 메인 DB | Supabase (PostgreSQL) | 유저 프로필, 매칭 이력, 채팅 메타데이터 |
| 벡터 DB | pgvector (halfvec) | 벡터 유사도 검색, 100만까지 충분 |
| 이미지 저장소 | Supabase Storage 또는 S3 | 원본/블러 처리된 사진 저장 |
| 캐시 | Redis | 매칭 큐, 세션, 실시간 데이터 |

### 7.4 AI/ML 파이프라인

| 구분 | 선택 | 이유 |
|------|------|------|
| 스타일 임베딩 | Marqo-FashionSigLIP (768차원) | 패션 도메인 SOTA, 소재/핏/컬러톤 구분 |
| 의류 파싱 | SCHP (20개 파트) | 상의/하의/코트/신발 등 세밀한 분리 |
| 체형 분석 | MediaPipe Pose | 33개 랜드마크 기반 체형 비율 추출 |
| 얼굴 감지/블러 | MediaPipe Face Detection | 실시간 얼굴 감지 및 블러 처리 |
| 컬러 분석 | OpenCV + K-Means | 의류 영역 색상 클러스터링 |
| ML 서빙 | Modal 또는 Replicate | GPU 추론, 콜드스타트 허용 배치 처리 |

### 7.5 인프라

| 구분 | 선택 | 이유 |
|------|------|------|
| 호스팅 | Railway 또는 Fly.io | 초기 비용 효율적 |
| GPU 추론 | Modal 또는 Replicate | CLIP, Pose 모델 서빙 |
| CI/CD | GitHub Actions | 자동 빌드, 테스트, 배포 |
| 모니터링 | Sentry + Posthog | 에러 트래킹 + 유저 행동 분석 |

### 7.6 아키텍처

```
┌─────────────┐     ┌─────────────┐
│  RN App     │     │  Next.js    │
│  (Expo)     │     │  (Admin)    │
└──────┬──────┘     └──────┬──────┘
       │                   │
       └────────┬──────────┘
                │ REST / WebSocket
       ┌────────▼────────┐
       │   FastAPI        │
       │   (API Server)   │
       └──┬─────┬─────┬──┘
          │     │     │
    ┌─────▼─┐ ┌▼───┐ ┌▼──────────┐
    │Supa   │ │Redis│ │Celery     │
    │base   │ │     │ │Workers    │
    │(PG +  │ └─────┘ └─────┬─────┘
    │Vector │               │
    │+Auth) │        ┌──────▼──────┐
    └───────┘        │ Modal/      │
                     │ Replicate   │
                     │ (GPU ML)    │
                     └─────────────┘
```

---

## 8. 리스크 및 대응

| 리스크 | 대응 |
|--------|------|
| 얼굴 우회 업로드 | 업로드 시 얼굴 감지 후 강제 블러, 신고 시스템 |
| 벡터 품질 (사진 1~2장) | 최소 3장 강제 + 온보딩 태그로 보정 |
| 콜드스타트 (초기 유저 부족) | 지역 한정 런칭 (서울 강남/홍대), 클로즈드 베타 |
| "결국 체형 앱" 논란 | 컬러, 무드, 핏 강조. 스타일 매칭으로 포지셔닝 |
| SCHP 세그멘테이션 오류 | 초기엔 전신 통 임베딩으로 시작, 점진적 업그레이드 |

---

## 9. 타임라인 (원맨팀, AI 기반 개발)

| 기간 | 마일스톤 |
|------|----------|
| Week 1~2 | 서비스 기획 확정, DB 스키마, API 설계 |
| Week 3~4 | 온보딩 플로우 (RN) + 벡터 생성 파이프라인 (FashionSigLIP + Pose) |
| Week 5~6 | 매칭 알고리즘 + 추천 API |
| Week 7~8 | 채팅 + Reveal + 프로필 UI |
| Week 9~10 | 얼굴 블러 파이프라인 + 전체 통합 테스트 |
| Week 11~12 | 클로즈드 베타 (50~100명) + 피드백 반영 |

---

## 관련 문서

- [[2026-03-13 AI 콘텐츠 생성]] - AI 사업 브레인스토밍
- [[RAG]] - 벡터 검색 기반 기술
- [[AI 네이티브 엔지니어]] - AI 기반 개발 방식

---

## 참고 자료

- [CLIP: Connecting text and images | OpenAI](https://openai.com/index/clip/) - CLIP 원본 논문 및 개요
- [Marqo-FashionSigLIP | HuggingFace](https://huggingface.co/Marqo/marqo-fashionSigLIP) - 패션 특화 임베딩 모델
- [SCHP: Self-Correction for Human Parsing](https://github.com/GoGoDuck912/Self-Correction-Human-Parsing) - 인체 파싱 모델
- [MediaPipe Pose](https://github.com/google-ai-edge/mediapipe/blob/master/docs/solutions/pose.md) - 체형 랜드마크 추출
- [pgvector](https://github.com/pgvector/pgvector) - PostgreSQL 벡터 검색 확장

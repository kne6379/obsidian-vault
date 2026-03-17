---
created: 2026-03-17
updated: 2026-03-17
tags: [concept, ai, llm, tools]
status: done
---

# 평가 하네스

> 언어 모델의 성능을 다양한 벤치마크에 대해 표준화된 방식으로 측정하는 프레임워크입니다. 대표적으로 EleutherAI의 LM Evaluation Harness(lm-eval)가 업계 사실상 표준으로 사용됩니다.

---

## 1. 정의

평가 하네스(Evaluation Harness)는 언어 모델을 여러 벤치마크에 대해 일관된 조건으로 평가하는 소프트웨어 프레임워크입니다. 개별 벤치마크가 "시험 문제"라면, 하네스는 그 시험을 운영하는 "시험 감독관"에 해당합니다.

EleutherAI가 개발한 **LM Evaluation Harness**(이하 lm-eval)는 이 분야의 사실상 표준입니다. Hugging Face의 Open LLM Leaderboard 백엔드로 사용되며, NVIDIA, Cohere, BigScience, Mosaic ML 등 수십 개 조직이 내부적으로 활용합니다. 수백 편의 논문에서 인용되었습니다.

---

## 2. 등장 배경 및 필요성

LLM 평가에는 세 가지 핵심 문제가 있었습니다.

- **재현성 부재**: 각 연구팀이 벤치마크를 자체 구현하면서 동일한 벤치마크라도 구현 차이로 점수가 달라지는 문제가 발생했습니다.
- **투명성 부족**: 평가 코드가 공개되지 않거나, 프롬프트 형식·퓨샷 구성 등 세부 설정이 논문에 명시되지 않는 경우가 많았습니다.
- **비교 불가능성**: 모델마다 다른 코드, 다른 설정으로 평가하면 공정한 비교가 불가능합니다.

lm-eval은 이 세 문제를 해결하기 위해, 모든 모델이 "동일한 입력과 동일한 코드베이스"에서 평가되는 통합 프레임워크로 설계되었습니다.

---

## 3. 작동 원리 / 핵심 개념

### 3.1 아키텍처

lm-eval은 평가 로직과 모델 구현을 분리하는 구조입니다.

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  모델 백엔드  │ ──▶ │  평가 엔진     │ ◀── │  태스크 정의  │
│ (HF, vLLM,  │     │ (프롬프트 구성, │     │ (YAML 설정)  │
│  OpenAI 등)  │     │  점수 계산)    │     │              │
└─────────────┘     └──────────────┘     └─────────────┘
                           │
                    ┌──────▼──────┐
                    │  결과 출력    │
                    │ (acc, F1 등) │
                    └─────────────┘
```

- **모델 백엔드**: HuggingFace Transformers, vLLM, GGUF(llama.cpp), OpenAI API, Anthropic API 등 다양한 백엔드를 지원합니다.
- **태스크 정의**: YAML 파일로 선언적으로 정의합니다. 프롬프트 형식, 퓨샷 수, 평가 지표 등을 설정합니다.
- **평가 엔진**: 프롬프트를 구성하고, 모델 출력의 로그 확률을 계산하여 점수를 산출합니다.

### 3.2 지원 벤치마크

400개 이상의 태스크를 지원하며, 주요 벤치마크는 다음과 같습니다.

| 벤치마크 | 측정 역량 | 평가 방식 |
|----------|-----------|-----------|
| MMLU | 57개 과목의 지식 이해도 | 4지선다, 로그 확률 기반 선택 |
| HellaSwag | 상식 추론 (문장 완성) | 문맥 이후 가장 적절한 후속 문장 선택 |
| ARC | 과학적 추론 | 객관식 |
| TruthfulQA | 진실성 (환각 저항) | 생성 및 객관식 |
| GSM8K | 수학 추론 | 단계별 풀이 정확도 |
| Winogrande | 대명사 해소(상식) | 이진 선택 |
| HumanEval | 코드 생성 | 함수 생성 후 테스트 통과율 |

### 3.3 평가 메커니즘

대부분의 벤치마크는 **로그 확률 기반 평가**를 사용합니다.

1. 프롬프트(문맥 + 퓨샷 예시)를 모델에 입력합니다.
2. 각 선택지를 이어붙인 후, 모델이 해당 선택지에 부여하는 로그 확률을 계산합니다.
3. 로그 확률 합이 가장 높은 선택지를 모델의 답으로 판정합니다.
4. 정답과 비교하여 정확도를 산출합니다.

이 방식은 모델이 실제로 텍스트를 생성하지 않아도 되므로 평가 속도가 빠르고, 결과가 결정적(deterministic)입니다.

### 3.4 사용 방법

CLI로 실행합니다.

```bash
lm_eval --model hf \
  --model_args pretrained=mistralai/Mistral-7B-v0.3 \
  --tasks mmlu,hellaswag \
  --num_fewshot 5 \
  --batch_size auto \
  --output_path results/
```

파이썬 API로도 사용 가능합니다.

```python
import lm_eval

results = lm_eval.simple_evaluate(
    model="hf",
    model_args="pretrained=mistralai/Mistral-7B-v0.3",
    tasks=["hellaswag", "mmlu"],
    num_fewshot=5,
)
```

주요 파라미터는 다음과 같습니다.

- `--model`: 모델 백엔드 (hf, vllm, openai 등)
- `--tasks`: 평가할 벤치마크 목록
- `--num_fewshot`: 퓨샷 예시 수 (0이면 제로샷)
- `--batch_size`: 배치 크기 (auto 권장)

---

## 4. 장점 및 이점

- **재현성 보장**: 동일한 코드베이스로 평가하므로 구현 차이에 의한 점수 변동이 없습니다.
- **공정한 비교**: 모든 모델이 동일한 입력, 동일한 조건에서 평가됩니다.
- **광범위한 호환성**: HuggingFace, vLLM, OpenAI API 등 주요 모델 인터페이스를 모두 지원합니다.
- **확장 용이**: YAML 기반 선언적 태스크 정의로 새로운 벤치마크를 쉽게 추가할 수 있습니다.
- **업계 표준**: Open LLM Leaderboard의 백엔드로 사용되어 결과의 신뢰도가 높습니다.

---

## 5. 한계점 및 고려사항

- **벤치마크 오염(Contamination)**: 학습 데이터에 벤치마크 문제가 포함될 경우 점수가 부풀려집니다. 하네스 자체는 이 문제를 해결하지 못합니다.
- **실제 활용 능력과의 괴리**: 벤치마크 점수가 높다고 해서 실제 사용자 경험이 좋다는 보장은 없습니다. 대화 능력, 지시 따르기 등은 별도 평가가 필요합니다.
- **로그 확률 방식의 한계**: 객관식 평가는 모델의 생성 능력을 직접 측정하지 못합니다. 실제 텍스트 생성 품질과 다를 수 있습니다.
- **리소스 요구량**: 400개 이상의 전체 태스크를 실행하면 상당한 GPU 시간이 필요합니다.

---

## 6. 실무 적용 가이드

### 6.1 주요 활용 사례

| 활용 사례 | 설명 |
|-----------|------|
| 모델 선택 | 후보 모델의 성능을 동일 조건에서 비교하여 최적 모델 선정 |
| 파인튜닝 검증 | 파인튜닝 전후 벤치마크 점수 변화로 학습 효과 측정 |
| 양자화 영향 분석 | FP16 → INT4 양자화 시 성능 하락 정도를 정량적으로 측정 |
| 릴리스 검증 | 모델 배포 전 성능이 기준선 이상인지 CI 파이프라인에서 자동 확인 |
| 리더보드 구축 | 조직 내부 모델 리더보드 운영 |

### 6.2 유사 도구 비교

| 도구 | 특징 | 적합 대상 |
|------|------|-----------|
| lm-eval (EleutherAI) | 400+ 벤치마크, 업계 표준, 로그 확률 기반 | 범용 LLM 벤치마킹 |
| HELM (Stanford) | 표준화된 시나리오, 다양한 지표(공정성, 독성 등) | 다면 평가가 필요한 연구 |
| OpenCompass | 대규모 벤치마크 스위트, 중국어 벤치마크 강점 | 다국어 모델 평가 |
| Chatbot Arena (LMSYS) | 사용자 투표 기반 ELO 평가 | 대화 품질 평가 |

---

## 관련 문서

- [[LLM]] - 평가 대상이 되는 대규모 언어 모델
- [[RAG]] - 검색 증강 생성 파이프라인의 성능 평가에도 하네스 활용 가능

---

## 참고 자료

- [EleutherAI LM Evaluation Harness GitHub](https://github.com/EleutherAI/lm-evaluation-harness) - 공식 저장소
- [EleutherAI 프로젝트 페이지](https://www.eleuther.ai/projects/large-language-model-evaluation) - 프로젝트 개요
- [Hugging Face Open LLM Leaderboard](https://huggingface.co/spaces/open-llm-leaderboard/open_llm_leaderboard) - lm-eval 기반 리더보드
- [New Task Guide](https://github.com/EleutherAI/lm-evaluation-harness/blob/main/docs/new_task_guide.md) - 커스텀 벤치마크 추가 가이드

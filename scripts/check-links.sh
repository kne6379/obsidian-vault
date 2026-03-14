#!/bin/bash

# 스테이징된 파일의 [[깨진링크]] 감지 스크립트
# pre-commit hook에서 호출됨

VAULT_DIR="$(git rev-parse --show-toplevel)"
TMPFILE=$(mktemp)
trap "rm -f $TMPFILE" EXIT

# 볼트 내 전체 .md 파일명 목록 (확장자 제외)
ALL_NAMES=$(find "$VAULT_DIR" -name "*.md" \
  -not -path "*/.obsidian/*" -not -path "*/.trash/*" -not -path "*/.git/*" \
  | xargs -I{} basename "{}" .md | sort -u)

# 스테이징된 .md 파일만 검사
STAGED=$(git diff --cached --name-only --diff-filter=ACM | grep "\.md$")

while IFS= read -r file; do
    [ -z "$file" ] && continue
    [ -f "$VAULT_DIR/$file" ] || continue
    # 링크 추출 후 한 줄씩 처리
    grep -oE '\[\[[^]]+\]\]' "$VAULT_DIR/$file" \
      | sed 's/\[\[//;s/\]\]//' | sed 's/|.*//' | sed 's/#.*//' \
      | while IFS= read -r link; do
        [ -z "$link" ] && continue
        echo "$ALL_NAMES" | grep -qxF "$link" || {
            echo "BROKEN: $file -> [[$link]]"
        }
    done
done <<< "$STAGED" > "$TMPFILE"

BROKEN=$(wc -l < "$TMPFILE" | tr -d ' ')
if [ "$BROKEN" -gt 0 ]; then
    cat "$TMPFILE"
    echo "${BROKEN}개의 끊어진 링크 발견"
fi
exit 0

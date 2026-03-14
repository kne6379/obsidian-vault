#!/bin/bash

# 스테이징된 파일의 [[깨진링크]] 감지 스크립트
# pre-commit hook에서 호출됨

VAULT_DIR="$(git rev-parse --show-toplevel)"
BROKEN=0

# 볼트 내 전체 .md 파일명 목록 (확장자 제외)
ALL_NAMES=$(find "$VAULT_DIR" -name "*.md" \
  -not -path "*/.obsidian/*" -not -path "*/.trash/*" -not -path "*/.git/*" \
  | xargs -I{} basename "{}" .md | sort -u)

# 스테이징된 .md 파일만 검사
STAGED=$(git diff --cached --name-only --diff-filter=ACM | grep "\.md$")

for file in $STAGED; do
    [ -f "$VAULT_DIR/$file" ] || continue
    LINKS=$(grep -oE '\[\[[^]]+\]\]' "$VAULT_DIR/$file" \
      | sed 's/\[\[//;s/\]\]//' | sed 's/|.*//' | sed 's/#.*//')
    for link in $LINKS; do
        echo "$ALL_NAMES" | grep -qx "$link" || {
            echo "BROKEN: $file -> [[$link]]"
            BROKEN=$((BROKEN + 1))
        }
    done
done

[ $BROKEN -gt 0 ] && echo "$BROKEN개의 끊어진 링크 발견"
exit 0

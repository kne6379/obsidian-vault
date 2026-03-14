#!/bin/bash

# 전 영역 INDEX 업데이트 알림 스크립트
# pre-commit hook에서 호출됨

VAULT_DIR="$(git rev-parse --show-toplevel)"
AREAS=("knowledge" "projects" "ventures" "life")

for area in "${AREAS[@]}"; do
    ADDED=$(git diff --cached --name-only --diff-filter=A \
      | grep "^${area}/.*\.md$" | grep -v "/_meta/" | grep -v "/_templates/")
    DELETED=$(git diff --cached --name-only --diff-filter=D \
      | grep "^${area}/.*\.md$" | grep -v "/_meta/" | grep -v "/_templates/")

    if [ -n "$ADDED" ] || [ -n "$DELETED" ]; then
        echo "[$area] INDEX 업데이트 필요:"
        for f in $ADDED; do echo "  + $(basename "$f" .md)"; done
        for f in $DELETED; do echo "  - $(basename "$f" .md)"; done
    fi
done

exit 0

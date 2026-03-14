#!/bin/bash

# 파일 리네임 시 볼트 전체 [[링크]] 연쇄 업데이트 스크립트
# pre-commit hook에서 호출됨

VAULT_DIR="$(git rev-parse --show-toplevel)"

git diff --cached --name-status | grep "^R" | while IFS=$'\t' read _ old new; do
    old_name=$(basename "$old" .md)
    new_name=$(basename "$new" .md)
    [ "$old_name" = "$new_name" ] && continue

    echo "Rename: $old_name -> $new_name"
    grep -rl "\[\[$old_name" "$VAULT_DIR" --include="*.md" \
      | grep -v "/.git/" | while read ref; do
        sed -i '' "s/\[\[$old_name\]\]/\[\[$new_name\]\]/g;
                   s/\[\[$old_name|/\[\[$new_name|/g;
                   s/\[\[$old_name#/\[\[$new_name#/g" "$ref"
        echo "  Updated: $ref"
    done
done

git add -u

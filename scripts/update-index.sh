#!/bin/bash

# develop/concepts INDEX 자동 업데이트 스크립트
# pre-commit hook에서 호출됨

VAULT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONCEPTS_DIR="$VAULT_DIR/develop/concepts"
INDEX_FILE="$VAULT_DIR/develop/_meta/INDEX.md"

# 새로 추가된 concepts 파일 감지
NEW_FILES=$(git diff --cached --name-only --diff-filter=A | grep "^develop/concepts/.*\.md$")

if [ -z "$NEW_FILES" ]; then
    exit 0
fi

echo "📝 새 문서 감지됨. INDEX 업데이트가 필요합니다:"
for file in $NEW_FILES; do
    filename=$(basename "$file" .md)
    echo "  - $filename"
done

echo ""
echo "⚠️  다음 파일들을 수동으로 업데이트해주세요:"
echo "  - develop/_meta/INDEX.md (문서 목록, 통계, 최근 업데이트)"
echo "  - develop/_meta/GLOSSARY.md (새 용어가 있는 경우)"
echo ""
echo "또는 /review 명령어로 문서를 검수하세요."

# 경고만 하고 커밋은 허용
exit 0

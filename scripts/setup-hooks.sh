#!/bin/bash

# Git pre-commit 훅 설치 스크립트

VAULT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$VAULT_DIR/.git/hooks/pre-commit"

cat > "$HOOK" << 'EOF'
#!/bin/bash
VAULT_DIR="$(git rev-parse --show-toplevel)"
"$VAULT_DIR/scripts/check-index.sh"
"$VAULT_DIR/scripts/check-links.sh"
"$VAULT_DIR/scripts/update-links.sh"
EOF

chmod +x "$HOOK"
echo "Pre-commit hook installed."

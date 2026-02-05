
#!/usr/bin/env bash
set -e

COMMITS=$(git log origin/main..HEAD --pretty=%s)

echo "$COMMITS" | grep -Ev '^(feat|fix|chore|docs|security)(\(.+\))?:' && {
  echo "❌ Commit message policy violation"
  exit 1
}

echo "✅ Commit messages compliant"

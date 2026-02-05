#!/usr/bin/env bash
set -e

# Check commit messages between branch and HEAD
COMMITS=$(git log origin/dev..HEAD --pretty=%s)

echo "🔍 Validating commit messages:"
echo "$COMMITS"
echo "------------------------------"

# Enforce WP#<id> <message>
echo "$COMMITS" | grep -Ev '^WP#[0-9]+[[:space:]]+.+' && {
  echo "❌ Commit message policy violation"
  echo "Expected format: WP#<id> <message>"
  echo "Example: WP#166 Update app.ts"
  exit 1
}

echo "✅ Commit messages compliant"


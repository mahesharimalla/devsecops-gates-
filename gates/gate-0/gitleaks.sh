
#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Gate-0A: Gitleaks Secret Detection"

REPORT_DIR="security-reports/gitleaks"
REPORT_FILE="$REPORT_DIR/gitleaks-report.json"

mkdir -p "$REPORT_DIR"

gitleaks detect \
  --source . \
  --no-git \
  --redact \
  --report-format json \
  --report-path "$REPORT_FILE"

# If report exists and is non-empty → fail
if [ -s "$REPORT_FILE" ]; then
  COUNT=$(jq length "$REPORT_FILE")
  if [ "$COUNT" -gt 0 ]; then
    echo "❌ Gitleaks found $COUNT secrets"
    exit 1
  fi
fi

echo "✅ Gitleaks PASSED – No secrets detected"

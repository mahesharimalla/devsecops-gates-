#!/usr/bin/env bash
set -euo pipefail

echo "📊 Gate-1: SonarQube Metrics Enforcement"

# ---- Required env vars ----
: "${SONAR_HOST_URL:?SONAR_HOST_URL not set}"
: "${SONAR_TOKEN:?SONAR_TOKEN not set}"
: "${SONAR_PROJECT_KEY:?SONAR_PROJECT_KEY not set}"

# ---- Thresholds ----
MIN_COVERAGE=80
MAX_BLOCKER=0
MAX_CRITICAL=0

# ---- Try possible API base paths ----
API_BASES=(
  "${SONAR_HOST_URL}/api"
  "${SONAR_HOST_URL}/sonar/api"
)

API_BASE=""

for base in "${API_BASES[@]}"; do
  echo "🔍 Testing Sonar API base: $base"
  if curl -sf -u "${SONAR_TOKEN}:" "$base/system/status" | jq -e '.status' >/dev/null 2>&1; then
    API_BASE="$base"
    echo "✅ Using Sonar API base: $API_BASE"
    break
  fi
done

if [ -z "$API_BASE" ]; then
  echo "❌ Unable to determine SonarQube API base URL"
  exit 1
fi

# ---- Query metrics ----
RESPONSE=$(curl -sf \
  -u "${SONAR_TOKEN}:" \
  -H "Accept: application/json" \
  "${API_BASE}/measures/component?component=${SONAR_PROJECT_KEY}&metricKeys=coverage,blocker_issues,critical_issues")

# ---- Extract values ----
COVERAGE=$(echo "$RESPONSE" | jq -r '.component.measures[] | select(.metric=="coverage") | .value // "0"')
BLOCKERS=$(echo "$RESPONSE" | jq -r '.component.measures[] | select(.metric=="blocker_issues") | .value // "0"')
CRITICALS=$(echo "$RESPONSE" | jq -r '.component.measures[] | select(.metric=="critical_issues") | .value // "0"')

echo "📈 Coverage        : ${COVERAGE}%"
echo "🚨 Blocker Issues  : ${BLOCKERS}"
echo "🔥 Critical Issues : ${CRITICALS}"

FAILED=0

if (( $(echo "$COVERAGE < $MIN_COVERAGE" | bc -l) )); then
  echo "❌ Coverage below ${MIN_COVERAGE}%"
  FAILED=1
fi

if [ "$BLOCKERS" -gt "$MAX_BLOCKER" ]; then
  echo "❌ Blocker issues detected"
  FAILED=1
fi

if [ "$CRITICALS" -gt "$MAX_CRITICAL" ]; then
  echo "❌ Critical issues detected"
  FAILED=1
fi

if [ "$FAILED" -eq 1 ]; then
  echo "❌ Gate-1 METRICS CHECK FAILED"
  exit 1
fi

echo "✅ Gate-1 METRICS CHECK PASSED"

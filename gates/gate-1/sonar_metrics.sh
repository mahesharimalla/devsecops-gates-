#!/usr/bin/env bash
set -euo pipefail

echo "📊 Gate-1: SonarQube Metrics Enforcement"

: "${SONAR_HOST_URL:?SONAR_HOST_URL not set}"
: "${SONAR_TOKEN:?SONAR_TOKEN not set}"
: "${SONAR_PROJECT_KEY:?SONAR_PROJECT_KEY not set}"

MIN_COVERAGE=80
MAX_BLOCKER=0
MAX_CRITICAL=0

# ---- Try API base paths (auto-detect) ----
API_BASES=(
  "${SONAR_HOST_URL%/}/api"
  "${SONAR_HOST_URL%/}/sonar/api"
)

RESPONSE=""
API_USED=""

for API in "${API_BASES[@]}"; do
  echo "🔍 Trying Sonar API base: $API"

  RESPONSE=$(curl -s \
    -u "${SONAR_TOKEN}:" \
    -H "Accept: application/json" \
    "$API/measures/component?component=${SONAR_PROJECT_KEY}&metricKeys=coverage,blocker_issues,critical_issues")

  if echo "$RESPONSE" | jq -e . >/dev/null 2>&1; then
    API_USED="$API"
    break
  fi
done

if [ -z "$API_USED" ]; then
  echo "❌ Could not detect valid SonarQube API endpoint"
  echo "🔎 Response sample:"
  echo "$RESPONSE" | head -n 20
  exit 1
fi

echo "✅ Using Sonar API: $API_USED"

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

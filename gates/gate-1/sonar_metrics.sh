
#!/usr/bin/env bash
set -euo pipefail

echo "📊 Gate-1: SonarQube Metrics Enforcement"

# ---- Required env vars ----
: "${SONAR_HOST_URL:?SONAR_HOST_URL not set}"
: "${SONAR_TOKEN:?SONAR_TOKEN not set}"
: "${SONAR_PROJECT_KEY:?SONAR_PROJECT_KEY not set}"

# ---- Configurable thresholds ----
MIN_COVERAGE=80
MAX_BLOCKER=0
MAX_CRITICAL=0

# ---- Query SonarQube measures API ----
RESPONSE=$(curl -s \
  -u "${SONAR_TOKEN}:" \
  -H "Accept: application/json" \
  "${SONAR_HOST_URL}/api/measures/component?component=${SONAR_PROJECT_KEY}&metricKeys=coverage,blocker_issues,critical_issues")

echo "🔎 Sonar API response received"

# ---- Extract values ----
COVERAGE=$(echo "$RESPONSE" | jq -r '.component.measures[] | select(.metric=="coverage") | .value // "0"')
BLOCKERS=$(echo "$RESPONSE" | jq -r '.component.measures[] | select(.metric=="blocker_issues") | .value // "0"')
CRITICALS=$(echo "$RESPONSE" | jq -r '.component.measures[] | select(.metric=="critical_issues") | .value // "0"')

echo "📈 Coverage        : ${COVERAGE}%"
echo "🚨 Blocker Issues  : ${BLOCKERS}"
echo "🔥 Critical Issues : ${CRITICALS}"

# ---- Enforce policies ----
FAILED=0

if (( $(echo "$COVERAGE < $MIN_COVERAGE" | bc -l) )); then
  echo "❌ Coverage below threshold (${MIN_COVERAGE}%)"
  FAILED=1
fi

if [ "$BLOCKERS" -gt "$MAX_BLOCKER" ]; then
  echo "❌ Blocker issues detected (${BLOCKERS})"
  FAILED=1
fi

if [ "$CRITICALS" -gt "$MAX_CRITICAL" ]; then
  echo "❌ Critical issues detected (${CRITICALS})"
  FAILED=1
fi

# ---- Final result ----
if [ "$FAILED" -eq 1 ]; then
  echo "❌ Gate-1 METRICS CHECK FAILED"
  exit 1
fi

echo "✅ Gate-1 METRICS CHECK PASSED"

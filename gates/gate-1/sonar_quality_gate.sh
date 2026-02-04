#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Gate-1: SonarQube Quality Gate"

: "${SONAR_HOST_URL:?SONAR_HOST_URL not set}"
: "${SONAR_TOKEN:?SONAR_TOKEN not set}"
: "${SONAR_PROJECT_KEY:?SONAR_PROJECT_KEY not set}"

RESPONSE=$(curl -s \
  -u "${SONAR_TOKEN}:" \
  "${SONAR_HOST_URL}/api/qualitygates/project_status?projectKey=${SONAR_PROJECT_KEY}")

echo "🔎 Sonar response:"
echo "$RESPONSE"

STATUS=$(echo "$RESPONSE" | jq -r '.projectStatus.status')

if [[ "$STATUS" != "OK" ]]; then
  echo "❌ SonarQube Quality Gate FAILED (status=$STATUS)"
  exit 1
fi

echo "✅ SonarQube Quality Gate PASSED"

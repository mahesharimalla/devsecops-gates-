#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Gate-1: SonarQube Quality Gate"

STATUS=$(curl -s -u "lms_sonartoken:" \
  "sonar_server/api/qualitygates/project_status?projectKey=lms" \
  | jq -r '.projectStatus.status')

if [ "$STATUS" != "OK" ]; then
  echo "❌ SonarQube Quality Gate FAILED ($STATUS)"
  exit 1
fi

echo "✅ SonarQube Quality Gate PASSED"

#!/usr/bin/env bash
set -euo pipefail

echo "⏱️ Gate-4: Performance SLA"

AVG_RESPONSE=$(jq '.aggregate.average.responseTime' perf-report.json)

awk "BEGIN {exit !($AVG_RESPONSE <= 2000)}"

echo "✅ Response time within SLA"

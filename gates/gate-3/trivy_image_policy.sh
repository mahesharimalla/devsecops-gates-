#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Gate-3: Trivy Image Policy"

IMAGE="$IMAGE_NAME"

trivy image --severity CRITICAL,HIGH --exit-code 1 "$IMAGE"

echo "✅ Image vulnerability policy compliant"

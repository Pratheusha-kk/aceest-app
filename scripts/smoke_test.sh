#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:5000}"

curl -fsS "${BASE_URL}/health"
curl -fsS "${BASE_URL}/version"
curl -fsS "${BASE_URL}/programs"
curl -fsS "${BASE_URL}/estimate-calories?program=Fat%20Loss%20(FL)&weight_kg=80"

echo
echo "ACEest smoke test passed for ${BASE_URL}"

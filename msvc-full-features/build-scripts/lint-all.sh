#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

msvc-full-features/build-scripts/lint-json.sh
msvc-full-features/tools/dialogue_validator.py data/json/npcs/* data/json/npcs/*/* data/json/npcs/*/*/*

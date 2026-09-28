#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

msvc-full-features/build-scripts/fmt.sh

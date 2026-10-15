#!/usr/bin/env bash
# Deploy from this standard checkout; no Git operations or downloads are implicit.
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
exec python3 "$repo_dir/scripts/setup.py" "$@"

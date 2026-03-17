#!/usr/bin/env bash

# Usage: ./push_large_files.sh [directory]
# Default: current directory

set -euo pipefail

ROOT_DIR="${1:-.}"

# Find files >10MB and process safely
find "$ROOT_DIR" -type f -size +10M -print0 | while IFS= read -r -d '' file; do
    echo "Pushing: $file"
    gcspush "$file"
done

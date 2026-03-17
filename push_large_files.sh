#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   gcspush_all [directory] [size]
# Examples:
#   gcspush_all .           # default 10M
#   gcspush_all . 50M       # 50 MB
#   gcspush_all . 1G        # 1 GB

ROOT_DIR="${1:-.}"
SIZE="${2:-10M}"

echo "Scanning: $ROOT_DIR"
echo "Pushing files larger than: $SIZE"

find -L "$ROOT_DIR" -type f -size +"$SIZE" -print0 | \
while IFS= read -r -d '' file; do
    echo "Pushing: $file"
    gcspush "$file"
done

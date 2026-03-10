#!/usr/bin/env bash
set -euo pipefail

# Require git repo
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "ERROR: run this test from inside an existing git repository"
  exit 1
}

command -v gcspush >/dev/null || { echo "gcspush not installed"; exit 1; }
command -v gcspull >/dev/null || { echo "gcspull not installed"; exit 1; }
command -v gcsinit >/dev/null || { echo "gcsinit not installed"; exit 1; }

TEST_DIR="gcs_test_$$"

echo "Creating test data in $TEST_DIR"

mkdir -p "$TEST_DIR/data"
mkdir -p "$TEST_DIR/models/run1/subdir"

printf 'hello world\n' > "$TEST_DIR/data/sample.txt"
printf 'alpha\n' > "$TEST_DIR/models/run1/a.txt"
printf 'beta\n' > "$TEST_DIR/models/run1/subdir/b.txt"

echo "Initializing bucket"
gcsinit

echo "Uploading file"
gcspush "$TEST_DIR/data/sample.txt"

echo "Uploading directory"
gcspush "$TEST_DIR/models/run1"

test -f "$TEST_DIR/data/sample.txt.gcs"
test -f "$TEST_DIR/models/run1.gcs"

echo "Removing local copies"
rm -f "$TEST_DIR/data/sample.txt"
rm -rf "$TEST_DIR/models/run1"

echo "Restoring file"
gcspull "$TEST_DIR/data/sample.txt.gcs"

echo "Restoring directory"
gcspull "$TEST_DIR/models"

test -f "$TEST_DIR/data/sample.txt"
test -f "$TEST_DIR/models/run1/a.txt"
test -f "$TEST_DIR/models/run1/subdir/b.txt"

cmp <(printf 'hello world\n') "$TEST_DIR/data/sample.txt"
cmp <(printf 'alpha\n') "$TEST_DIR/models/run1/a.txt"
cmp <(printf 'beta\n') "$TEST_DIR/models/run1/subdir/b.txt"

echo
echo "PASS: push/pull test succeeded"

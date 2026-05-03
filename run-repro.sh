#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT/logs"
TOOL_DIR="$ROOT/tools"
mkdir -p "$LOG_DIR"
mkdir -p "$TOOL_DIR"

TARGET="${TARGET:-runAll}"
JOBS="${JOBS:-4}"
LOCK_FLAG="${LOCK_FLAG:---no-build-lock}"

ensure_mill() {
  local version="$1"
  local mill_bin="$TOOL_DIR/mill-$version"
  local url="https://repo1.maven.org/maven2/com/lihaoyi/mill-dist/$version/mill-dist-$version-mill.sh"

  if [ ! -x "$mill_bin" ]; then
    echo "Downloading Mill $version" >&2
    curl -fL "$url" -o "$mill_bin"
    chmod +x "$mill_bin"
  fi

  echo "$mill_bin"
}

run_one() {
  local label="$1"
  local mill_bin="$2"
  local log="$LOG_DIR/${label}.log"

  rm -rf "$ROOT/out"

  echo "== $label =="
  echo "mill: $mill_bin"
  echo "target: $TARGET"
  echo "jobs: $JOBS"
  echo "lock flag: $LOCK_FLAG"
  echo "log: $log"

  (
    cd "$ROOT"
    /usr/bin/time -p "$mill_bin" "$LOCK_FLAG" --jobs "$JOBS" "$TARGET"
  ) 2>&1 | tee "$log"
}

case "${1:-both}" in
  1.1.6)
    run_one "mill-1.1.6" "$(ensure_mill 1.1.6)"
    ;;
  1.1.5-271-1a2289)
    run_one "mill-1.1.5-271-1a2289" "$(ensure_mill 1.1.5-271-1a2289)"
    ;;
  both)
    run_one "mill-1.1.6" "$(ensure_mill 1.1.6)"
    run_one "mill-1.1.5-271-1a2289" "$(ensure_mill 1.1.5-271-1a2289)"
    ;;
  *)
    echo "usage: $0 [both|1.1.6|1.1.5-271-1a2289]" >&2
    exit 2
    ;;
esac

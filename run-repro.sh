#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT/logs"
TOOL_DIR="$ROOT/tools"
mkdir -p "$LOG_DIR"
mkdir -p "$TOOL_DIR"

TARGET="${TARGET:-runAll}"
JOBS="${JOBS:-4}"

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
  local lock_mode="$3"
  local log_dir="$LOG_DIR/$lock_mode"
  local log="$log_dir/${label}.log"
  local lock_args=()

  mkdir -p "$log_dir"

  case "$lock_mode" in
    normal)
      ;;
    no-build-lock)
      lock_args=(--no-build-lock)
      ;;
    *)
      echo "unknown lock mode: $lock_mode" >&2
      exit 2
      ;;
  esac

  rm -rf "$ROOT/out"

  echo "== $label =="
  echo "mill: ./tools/$(basename "$mill_bin")"
  echo "target: $TARGET"
  echo "jobs: $JOBS"
  echo "lock mode: $lock_mode"
  echo "log: ./logs/$lock_mode/${label}.log"

  (
    cd "$ROOT"
    /usr/bin/time -p "$mill_bin" "${lock_args[@]}" --jobs "$JOBS" "$TARGET"
  ) 2>&1 | tee "$log"
}

run_version() {
  local version="$1"
  local lock_mode="$2"
  run_one "mill-$version" "$(ensure_mill "$version")" "$lock_mode"
}

run_versions() {
  local version_mode="$1"
  local lock_mode="$2"

  case "$version_mode" in
    1.1.6)
      run_version 1.1.6 "$lock_mode"
      ;;
    1.1.5-271-1a2289)
      run_version 1.1.5-271-1a2289 "$lock_mode"
      ;;
    both)
      run_version 1.1.6 "$lock_mode"
      run_version 1.1.5-271-1a2289 "$lock_mode"
      ;;
    *)
      echo "usage: $0 [both|1.1.6|1.1.5-271-1a2289] [all|normal|no-build-lock]" >&2
      exit 2
      ;;
  esac
}

case "${2:-all}" in
  normal | no-build-lock)
    run_versions "${1:-both}" "$2"
    ;;
  all)
    run_versions "${1:-both}" normal
    run_versions "${1:-both}" no-build-lock
    ;;
  *)
    echo "usage: $0 [both|1.1.6|1.1.5-271-1a2289] [all|normal|no-build-lock]" >&2
    exit 2
    ;;
esac

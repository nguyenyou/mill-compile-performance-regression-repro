#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT/logs/compile-lab"
PROFILE_DIR="$ROOT/logs/compile-lab-profiles"
TOOL_DIR="$ROOT/tools"
mkdir -p "$LOG_DIR" "$PROFILE_DIR" "$TOOL_DIR"

VERSIONS="${VERSIONS:-1.1.6 1.1.5-271-1a2289 1.1.5-274-8a195b}"
LOCK_MODES="${LOCK_MODES:-normal no-build-lock}"
JOBS="${JOBS:-4}"
TARGET="${TARGET:-compileLab}"
FILES="${FILES:-80}"
COMMON_FILES="${COMMON_FILES:-$FILES}"
CHAIN_FILES="${CHAIN_FILES:-$FILES}"
SIDE_FILES="${SIDE_FILES:-$FILES}"
METHODS="${METHODS:-80}"

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
  local version="$1"
  local lock_mode="$2"
  local mill_bin
  mill_bin="$(ensure_mill "$version")"

  local lock_args=()
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

  local log_dir="$LOG_DIR/$lock_mode"
  local profile_dir="$PROFILE_DIR/$lock_mode/mill-$version"
  local log="$log_dir/mill-$version.log"
  mkdir -p "$log_dir" "$profile_dir"

  rm -rf "$ROOT/out"

  echo "== mill-$version / $lock_mode =="
  echo "target: $TARGET"
  echo "jobs: $JOBS"
  echo "common files: $COMMON_FILES"
  echo "chain files per module: $CHAIN_FILES"
  echo "side files per module: $SIDE_FILES"
  echo "methods per file: $METHODS"
  echo "log: ${log#"$ROOT"/}"

  (
    cd "$ROOT"
    COMMON_FILES="$COMMON_FILES" CHAIN_FILES="$CHAIN_FILES" SIDE_FILES="$SIDE_FILES" \
      METHODS="$METHODS" ./generate-compile-sources.sh
    /usr/bin/time -p "$mill_bin" "${lock_args[@]}" --jobs "$JOBS" "$TARGET"
  ) 2>&1 | tee "$log"

  cp "$ROOT/out/mill-profile.json" "$profile_dir/mill-profile.json" 2>/dev/null || true
  cp "$ROOT/out/mill-chrome-profile.json" "$profile_dir/mill-chrome-profile.json" 2>/dev/null || true
}

for lock_mode in $LOCK_MODES; do
  for version in $VERSIONS; do
    run_one "$version" "$lock_mode"
  done
done

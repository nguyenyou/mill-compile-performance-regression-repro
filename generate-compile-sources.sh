#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILES="${FILES:-80}"
COMMON_FILES="${COMMON_FILES:-$FILES}"
CHAIN_FILES="${CHAIN_FILES:-$FILES}"
SIDE_FILES="${SIDE_FILES:-$FILES}"
METHODS="${METHODS:-80}"
STAMP="$ROOT/.compile-lab-sources"
STAMP_VALUE="common_files=$COMMON_FILES chain_files=$CHAIN_FILES side_files=$SIDE_FILES methods=$METHODS"

modules=(common chain0 chain1 chain2 chain3 side0 side1 side2 side3 side4 side5 side6 side7)

if [ -f "$STAMP" ] && [ "$(cat "$STAMP")" = "$STAMP_VALUE" ]; then
  exit 0
fi

for module in "${modules[@]}"; do
  rm -rf "$ROOT/$module"
done

write_common_file() {
  local file_no="$1"
  local class_name
  class_name="$(printf 'Common%03d' "$file_no")"
  local out="$ROOT/common/src/lab/common/$class_name.scala"
  mkdir -p "$(dirname "$out")"

  {
    echo "package lab.common"
    echo
    echo "final class $class_name(val value: Int) {"
    local method_no
    for method_no in $(seq 1 "$METHODS"); do
      printf '  def f%03d(input: Int): Int = value + input + %d\n' "$method_no" "$method_no"
    done
    echo "}"
    echo
    echo "object $class_name {"
    printf '  val seed: Int = %d\n' "$file_no"
    echo "}"
  } > "$out"
}

write_dependent_file() {
  local module="$1"
  local file_no="$2"
  local class_prefix="$3"
  local class_name
  class_name="$(printf '%s%03d' "$class_prefix" "$file_no")"
  local out="$ROOT/$module/src/lab/$module/$class_name.scala"
  mkdir -p "$(dirname "$out")"

  {
    echo "package lab.$module"
    echo
    echo "import lab.common.*"
    echo
    echo "final class $class_name(val value: Int) {"
    local method_no
    for method_no in $(seq 1 "$METHODS"); do
      local common_no=$(( (method_no % COMMON_FILES) + 1 ))
      local common_name
      common_name="$(printf 'Common%03d' "$common_no")"
      printf '  def f%03d(input: Int): Int = new %s(value).f%03d(input) + %d\n' \
        "$method_no" "$common_name" "$method_no" "$method_no"
    done
    echo "}"
    echo
    echo "object $class_name {"
    printf '  val seed: Int = %d\n' "$file_no"
    echo "}"
  } > "$out"
}

for file_no in $(seq 1 "$COMMON_FILES"); do
  write_common_file "$file_no"
done

for module in chain0 chain1 chain2 chain3; do
  prefix="$(tr '[:lower:]' '[:upper:]' <<< "${module:0:1}")${module:1}"
  for file_no in $(seq 1 "$CHAIN_FILES"); do
    write_dependent_file "$module" "$file_no" "$prefix"
  done
done

for module in side0 side1 side2 side3 side4 side5 side6 side7; do
  prefix="$(tr '[:lower:]' '[:upper:]' <<< "${module:0:1}")${module:1}"
  for file_no in $(seq 1 "$SIDE_FILES"); do
    write_dependent_file "$module" "$file_no" "$prefix"
  done
done

echo "$STAMP_VALUE" > "$STAMP"
echo "Generated compile lab sources: $STAMP_VALUE"

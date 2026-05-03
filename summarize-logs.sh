#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

while IFS= read -r log; do
  [ -f "$log" ] || continue
  echo "== ${log#"$ROOT"/logs/} =="
  awk '
    /MARK/ {
      for (i = 1; i <= NF; i++) {
        if ($i == "MARK") {
          phase = $(i + 1)
          name = $(i + 2)
          ts = $(i + 3)
          if (base == "") base = ts
          printf "%8.3fs  %-5s  %s\n", (ts - base) / 1000, phase, name
        }
      }
    }
    /^real / { print "real     " $2 "s" }
  ' "$log"
done < <(find "$ROOT/logs" -type f -name '*.log' | sort)

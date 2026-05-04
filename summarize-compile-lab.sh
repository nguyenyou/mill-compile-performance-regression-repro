#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 - "$ROOT" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
compile_re = re.compile(r"\] (?:(?P<label>.+?\.compile) )?compiling .* to .*?/(?P<path>[^ ]*?)/compile\.dest/classes")
real_re = re.compile(r"^real (?P<seconds>[0-9.]+)$")
success_re = re.compile(r"SUCCESS\] .* (?P<seconds>[0-9]+)s$")

def label_from_path(path: str) -> str:
    return path.replace("/", ".") + ".compile"

for log in sorted((root / "logs" / "compile-lab").glob("*/*.log")):
    starts = []
    real = None
    mill = None
    params = []
    for line in log.read_text(errors="replace").splitlines():
        if line.startswith("Mill Build Tool version "):
            mill = line.removeprefix("Mill Build Tool version ").strip()
        if line.startswith(("common files:", "chain files per module:", "side files per module:", "methods per file:", "jobs:")):
            params.append(line.strip())
        m = compile_re.search(line)
        if m:
            starts.append(m.group("label") or label_from_path(m.group("path")))
        m = real_re.match(line)
        if m:
            real = float(m.group("seconds"))
        m = success_re.search(line)
        if m and real is None:
            real = float(m.group("seconds"))

    print(f"== {log.relative_to(root / 'logs' / 'compile-lab')} ==")
    if mill:
        print(f"mill: {mill}")
    if real is not None:
        print(f"real: {real:.2f}s")
    for param in params:
        print(param)
    print(f"compile starts: {len(starts)}")
    if starts:
        if "chain0.compile" in starts:
            print(f"chain0 rank: {starts.index('chain0.compile') + 1}")
        print("first 8:")
        for i, label in enumerate(starts[:8], 1):
            print(f"  {i:02d}. {label}")
        print("last 8:")
        for i, label in enumerate(starts[-8:], len(starts) - 7):
            print(f"  {i:02d}. {label}")
    print()
PY

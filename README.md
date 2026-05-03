# Mill Scheduler Repro

This repro compares:

- `tools/mill-1.1.6`
- `tools/mill-1.1.5-271-1a2289`

`run-repro.sh` downloads both pinned Mill launchers into `tools/` on demand.

Run both Mill versions in both lock modes:

```bash
./run-repro.sh
```

Run one Mill version:

```bash
./run-repro.sh 1.1.6
./run-repro.sh 1.1.5-271-1a2289
```

Run one lock mode:

```bash
./run-repro.sh both normal
./run-repro.sh both no-build-lock
```

Defaults:

- `TARGET=runAll`
- `JOBS=4`
- lock modes: `normal`, `no-build-lock`

Expected shape:

```text
aSlowRoot -------- slow --------> aAfterSlow
                                      \
                                       runAll
                                      /
bFastRoot -------- fast --------> bLongAfterFast
```

The interesting line is when `bLongAfterFast` starts. If it starts before
`aSlowRoot` ends, unrelated ready work is overlapping. If it starts only after
`aAfterSlow` starts, the new lock-phase chain is delaying ready work behind an
unrelated same-height task.

Summarize the latest logs:

```bash
./summarize-logs.sh
```

The `logs/` directory contains committed sample output, so the behavior can be
inspected without rerunning the repro.

Observed:

```text
normal / 1.1.6:
  bLongAfterFast starts at +0.007s
  real 9.30s

normal / 1.1.5-271-1a2289:
  bLongAfterFast starts at +5.017s
  real 14.28s

no-build-lock / 1.1.6:
  bLongAfterFast starts at +0.007s
  real 9.09s

no-build-lock / 1.1.5-271-1a2289:
  bLongAfterFast starts at +5.018s
  real 13.99s
```

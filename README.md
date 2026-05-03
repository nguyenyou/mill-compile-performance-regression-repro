# Mill Scheduler Repro

This repro compares:

- `tools/mill-1.1.6`
- `tools/mill-1.1.5-271-1a2289`

`run-repro.sh` downloads both pinned Mill launchers into `tools/` on demand.

Run both:

```bash
./run-repro.sh both
```

Run one:

```bash
./run-repro.sh 1.1.6
./run-repro.sh 1.1.5-271-1a2289
```

Defaults:

- `TARGET=runAll`
- `JOBS=4`
- `LOCK_FLAG=--no-build-lock`

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

Observed on the initial warmed run:

```text
1.1.6:
  bLongAfterFast starts at +0.015s
  real 9.18s

1.1.5-271-1a2289:
  bLongAfterFast starts at +5.013s
  real 14.06s
```

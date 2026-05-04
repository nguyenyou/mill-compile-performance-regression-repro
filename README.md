# Mill Compile Performance Regression Repro

This repo investigates a Mill compile performance regression: `1.1.5-271-1a2289`
delays ready independent work, while `1.1.5-274-8a195b` fixes that specific
scheduler bug; the added compile lab does not yet reproduce the remaining
large-project slowdown.

## Table of Contents

- [What This Repro Shows](#what-this-repro-shows)
- [Results](#results)
- [Compile Lab](#compile-lab)
- [Logs](#logs)
- [How To Run](#how-to-run)

## What This Repro Shows

This repro compares Mill `1.1.6` against:

- `1.1.5-271-1a2289`: original dev build from the fine-grained concurrency PR
- `1.1.5-274-8a195b`: follow-up dev build with Li Haoyi's scheduler fix

The task graph has two independent branches:

```text
aSlowRoot -------- slow --------> aAfterSlow
                                      \
                                       runAll
                                      /
bFastRoot -------- fast --------> bLongAfterFast
```

`bFastRoot` finishes immediately, so `bLongAfterFast` should start immediately
and overlap with `aSlowRoot`.

In `1.1.5-271-1a2289`, `bLongAfterFast` waits about 5 seconds for the unrelated
slow branch. This happens with normal locking and with `--no-build-lock`.

In `1.1.5-274-8a195b`, `bLongAfterFast` starts immediately again, matching
`1.1.6`.

## Results

| Lock Mode | Mill Version | `bLongAfterFast` Start | Real Time |
| --- | --- | ---: | ---: |
| normal | `1.1.6` | `+0.007s` | `9.30s` |
| normal | `1.1.5-271-1a2289` | `+5.017s` | `14.28s` |
| normal | `1.1.5-274-8a195b` | `+0.008s` | `10.91s` |
| `--no-build-lock` | `1.1.6` | `+0.007s` | `9.09s` |
| `--no-build-lock` | `1.1.5-271-1a2289` | `+5.018s` | `13.99s` |
| `--no-build-lock` | `1.1.5-274-8a195b` | `+0.007s` | `10.88s` |

The important signal is the start time of `bLongAfterFast`:

- `1.1.6`: starts immediately after `bFastRoot`
- `1.1.5-271-1a2289`: starts only after `aSlowRoot` finishes
- `1.1.5-274-8a195b`: starts immediately again

## Compile Lab

The sleep-based repro above proves the scheduler bug, but it is not enough to
investigate the remaining large-project compile slowdown. The compile lab adds
a generated Scala project:

```text
common --> chain0 --> chain1 --> chain2 --> chain3
   |
   +----> side0
   +----> side1
   +----> ...
   +----> side7
```

The chain is the critical path. The side modules create parallel compiler
pressure. Source size is controlled by environment variables.

Latest committed compile-lab run:

- `COMMON_FILES=40`
- `CHAIN_FILES=60`
- `SIDE_FILES=120`
- `METHODS=60`
- `JOBS=4`

| Lock Mode | Mill Version | Real Time |
| --- | --- | ---: |
| normal | `1.1.6` | `14.19s` |
| normal | `1.1.5-271-1a2289` | `14.75s` |
| normal | `1.1.5-274-8a195b` | `13.81s` |
| `--no-build-lock` | `1.1.6` | `14.33s` |
| `--no-build-lock` | `1.1.5-271-1a2289` | `14.26s` |
| `--no-build-lock` | `1.1.5-274-8a195b` | `14.54s` |

This compile lab does not reproduce the remaining slowdown seen in the large
project. It is now a small place to keep adjusting graph shape/source size
without touching the real project.

## Logs

Sample logs are committed, so this can be inspected without rerunning the repro:

- `logs/normal/mill-1.1.6.log`
- `logs/normal/mill-1.1.5-271-1a2289.log`
- `logs/normal/mill-1.1.5-274-8a195b.log`
- `logs/no-build-lock/mill-1.1.6.log`
- `logs/no-build-lock/mill-1.1.5-271-1a2289.log`
- `logs/no-build-lock/mill-1.1.5-274-8a195b.log`
- `logs/compile-lab/...`
- `logs/compile-lab-profiles/...`

Summarize the committed logs:

```bash
./summarize-logs.sh
./summarize-compile-lab.sh
```

## How To Run

`run-repro.sh` downloads both pinned Mill launchers into `tools/` on demand.

Run both Mill versions in both lock modes:

```bash
./run-repro.sh
```

Run one Mill version:

```bash
./run-repro.sh 1.1.6
./run-repro.sh 1.1.5-271-1a2289
./run-repro.sh 1.1.5-274-8a195b
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

Run the compile lab:

```bash
./run-compile-lab.sh
```

Run the committed-size compile lab:

```bash
COMMON_FILES=40 CHAIN_FILES=60 SIDE_FILES=120 METHODS=60 JOBS=4 ./run-compile-lab.sh
```

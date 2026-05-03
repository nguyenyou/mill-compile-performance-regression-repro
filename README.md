# Mill Compile-Time Regression Repro

This demonstrates a compile-time regression in Mill `1.1.5-271-1a2289`: the new
lock-phase ordering can delay ready independent tasks behind unrelated slow
branches.

## Table of Contents

- [What This Repro Shows](#what-this-repro-shows)
- [Results](#results)
- [Logs](#logs)
- [How To Run](#how-to-run)

## What This Repro Shows

This repro compares Mill `1.1.6` against `1.1.5-271-1a2289`, the dev build from
the fine-grained concurrency PR.

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

## Results

| Lock Mode | Mill Version | `bLongAfterFast` Start | Real Time |
| --- | --- | ---: | ---: |
| normal | `1.1.6` | `+0.007s` | `9.30s` |
| normal | `1.1.5-271-1a2289` | `+5.017s` | `14.28s` |
| `--no-build-lock` | `1.1.6` | `+0.007s` | `9.09s` |
| `--no-build-lock` | `1.1.5-271-1a2289` | `+5.018s` | `13.99s` |

The important signal is the start time of `bLongAfterFast`:

- `1.1.6`: starts immediately after `bFastRoot`
- `1.1.5-271-1a2289`: starts only after `aSlowRoot` finishes

## Logs

Sample logs are committed, so this can be inspected without rerunning the repro:

- `logs/normal/mill-1.1.6.log`
- `logs/normal/mill-1.1.5-271-1a2289.log`
- `logs/no-build-lock/mill-1.1.6.log`
- `logs/no-build-lock/mill-1.1.5-271-1a2289.log`

Summarize the committed logs:

```bash
./summarize-logs.sh
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

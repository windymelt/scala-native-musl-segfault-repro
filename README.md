# Scala Native + musl + os-lib: intermittent segfault/hang reproduction

Minimal reproduction of an intermittent segfault or hang when using [os-lib](https://github.com/com-lihaoyi/os-lib) on Scala Native with musl static linking.

## Symptom

A musl-linked static binary that calls `os.proc().call()` intermittently fails at exit time. Depending on the environment, the failure manifests as either:

- **segfault (exit code 139)**: data race on the GC heap during finalization
- **hang (process never exits)**: a non-daemon thread outlives the main thread

The same code built with glibc (dynamic linking) does not exhibit the issue.

## Reproduction

Prerequisites: Docker

```sh
# Build the musl static binary
./build.sh repro.scala repro

# Run the test (200 iterations, 3s timeout each)
./test.sh ./repro
# => repro: segfault=0 hang=4 / 200
```

## Workaround

Call POSIX `_exit(2)` at the end of `main` to skip GC finalization entirely:

```sh
./build.sh repro-fixed.scala repro-fixed
./test.sh ./repro-fixed
# => repro-fixed: segfault=0 hang=0 / 200
```

See `repro-fixed.scala` for the fix.

## Root cause

os-lib's `os.proc().spawn()` creates a non-daemon `shutdownHookMonitorThread` that polls `Process.isAlive` and then calls `Runtime.removeShutdownHook`. This thread is never joined after `spawn()` / `call()` returns. When the main thread exits, the lingering thread races with Scala Native's runtime cleanup (GC finalization), causing a segfault or preventing the process from terminating.

Disabling the thread via `os.proc().spawn(destroyOnExit = false)` eliminates the issue.

Manually reconstructing the same thread pattern (shutdown hook + monitor thread + pumper threads) without os-lib does not reproduce the issue, suggesting that os-lib's internal implementation details (e.g., `SubProcess` object structure, circular `lazy val` references, geny library integration) interact with Scala Native + musl in a specific way.

## Triage summary

### os-lib API level

| Call | Result |
|------|--------|
| `os.proc().call()` | hang 2/30 |
| `os.proc().spawn(destroyOnExit = true)` | hang 5/200 |
| `os.proc().spawn(destroyOnExit = false)` | **0/200** |

### Without os-lib (all 0/200)

The following patterns were tested with musl static linking, all passing 200/200:

- Bare `Thread` (daemon/non-daemon) + `Thread.sleep`
- `Thread` + GC heap allocation
- `java.lang.ProcessBuilder` directly
- `ProcessBuilder` + shutdownHookMonitorThread + pumper threads (os-lib pattern reconstructed manually)
- `Runtime.removeShutdownHook` race only
- Circular `lazy val` pattern
- os-lib linked but using manual ProcessBuilder

### Confirmed not occurring on glibc

The same `repro.scala` built with glibc dynamic linking (`--native-linking "-static"` removed) passes 200/200.

## Environment

- Scala 3.3.7
- Scala Native 0.5.9 / 0.5.10
- os-lib 0.11.8
- Alpine Linux (edge), musl libc
- clang 21, lld 21

## License

BSD 2-Clause License. See [LICENSE](LICENSE).

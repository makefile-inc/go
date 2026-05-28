# makefile-go

Includes for Makefile for go operations like lint, test, build.

## Dependencies

Should be installed:
- `make`
- `curl` - it needs for download dependencies. By default, targes that needs curl
   check that its installed
- now we support only Linux and MacOS on x86 and ARM.

## Introduction

### Preparations
Now inclues files do next preparations for another targets:
- created directory for deps binaries, by default ./bin but can be changed with 
  `BINARIES_PATH` Makefile variable in [bin.mk](./makefile.inc/bin.mk).
  Target: `bin`.
- Checks that curl is installed for downloading dependencies 
  Target: `check/installed/curl`.
- Also, contains define `CHECK_BINARY` for check that deps is installed
  and have target version.
- `NOW_MICROSECONDS` and `HUMAN_DURATION_MICROSECONDS` defines for calculate
  and output durations (using for run tests) in [duration.mk](./makefile.inc/duration.mk)
- install needed deps for another targets (targets `install/go/deps` and `install/go/deps/lint`).
  All deps will be installed to `BINARIES_PATH`.
  For install we are using `CHECK_BINARY` define. It validates that binary installed and have 
  correct target version. Versions for deps stored in [versions.mk](./makefile.inc/versions.mk).
  Now, we need next deps:
  - `jq` - for human readable output for tests (install target `install/go/jq`)
  - `gofumpt` - for linting (install target `install/go/go-fumpt`)
  - `golangci-lint` - for linting (install target `install/go/golangci-lint`)
- removes binaries with target `clean/golang`

### Working targets

Now, we have next operations linting, run tests (with and without race).
All operations find all `go.mod` files in directory and 
run operations in every dir containing `go.mod`.

### Linting

Targets: `go/lint` and `go/lint/fix`.
Uses `golangci-lint`. Uses `.golangci.yaml` in root as config.
Befor linting targets cheks that `.golangci.yaml` presents. 

For run fix use `go/lint/fix` target.

### Testing

Targets: `go/test`, `go/test/race` and `go/test/force`.
Runs `go test` with `-v -p 1` arguments.
As you known, often heavy to find which test was failed in output of `go test`.
Targets output tests results in json-format for every dir to tmp file in  `./tmp/go-tests` directory with 
suffix `.json.test.result`, also output on screen default output. After run tests for directory, 
targets check tests was failed or not. If passed - remove file. If failed keep file. 
After runs tests in all directories, target output in pretty-print output for all failed tests (with red color).
After print all outputs, print all failed tests in order by counts of `/` in tests.
Output will like as in this example:

```
ok      github.com/name212/gotee_test/pkg/internal      0.003s
--- Unsuccessful test TestTeeStreamStop/Stop_stream_before_read_all ---
=== RUN   TestTeeStreamStop/Stop_stream_before_read_all
[github.com/name212/gotee][DEBUG][TEE_STREAM][rstop_before_read][RUN]: Start read
[github.com/name212/gotee][DEBUG][INTERNAL_PIPE][WRITE_CYCLE][not_full]: Start write
[github.com/name212/gotee][DEBUG][TEE_STREAM][rstop_before_read][STOP]: Send stop signal to reader cycle
[github.com/name212/gotee][DEBUG][TEE_STREAM][rstop_before_read][RUN]: Got stop signal in run handler
[github.com/name212/gotee][DEBUG][TEE_STREAM][rstop_before_read][RUN]: End read. Stop pipes
[github.com/name212/gotee][DEBUG][TEE_STREAM][rstop_before_read][RUN]: Close pipe for 'not_full'...
[github.com/name212/gotee][DEBUG][INTERNAL_PIPE][STOP][not_full]: Close writeCh
[github.com/name212/gotee][DEBUG][INTERNAL_PIPE][STOP][not_full]: No error. Waiting ending write...
[github.com/name212/gotee][DEBUG][INTERNAL_PIPE][WRITE_CYCLE][not_full]: Send err is nil
[github.com/name212/gotee][DEBUG][INTERNAL_PIPE][WRITE_CYCLE][not_full]: Close endCh
[github.com/name212/gotee][DEBUG][INTERNAL_PIPE][WRITE_CYCLE][not_full]: Write stopped
[github.com/name212/gotee][DEBUG][INTERNAL_PIPE][STOP][not_full]: Write ended. Close consumer...
[github.com/name212/gotee][DEBUG][INTERNAL_PIPE][STOP][not_full]: Stopped! Result err <nil>
[github.com/name212/gotee][DEBUG][TEE_STREAM][rstop_before_read][RUN]: All pipes were closed. Send stop to reader cycle...
[github.com/name212/gotee][DEBUG][TEE_STREAM][rstop_before_read][STOP]: Already stopped
[github.com/name212/gotee][DEBUG][TEE_STREAM][rstop_before_read][RUN]: Done without errors. Returns nil results
[github.com/name212/gotee][DEBUG][TEE_STREAM][rstop_before_read][READ_CYCLE]: Receive buf, send to Run; Consume 1; buf len: 1; buf: "F"
[github.com/name212/gotee][DEBUG][TEE_STREAM][rstop_before_read][READ_CYCLE]: Receive stop signal during send to outCh
    stream_tee_test.go:482: 
                Error Trace:    /home/nick/src/gotee/gotee_test/stream_tee_test.go:482
                Error:          Expected value not to be nil.
                Test:           TestTeeStreamStop/Stop_stream_before_read_all
                Messages:       results should nil
    --- FAIL: TestTeeStreamStop/Stop_stream_before_read_all (2.00s)
--- Unsuccessful test TestTeeStreamStop ---
=== RUN   TestTeeStreamStop
--- FAIL: TestTeeStreamStop (2.00s)

Unsuccessful tests:
TestTeeStreamStop
TestTeeStreamStop/Stop_stream_before_read_all
```

remove all output files and exit with 1 code. 

If all tests passed, output with green color the next string with duration:

```
PASS
ok      github.com/name212/gotee_test/pkg/internal      0.007s
Tests passed in 18.989497s!
```
end exit with 0 code.

For runinng tests with `-race` flag, use target `go/test/race`.

Target `go/test/force` re-run tests without cache.

## Checks go mod tidy run in CI

Often we need checks after add deps to golang code, that `go mod tidy` was run
and results were commited to sources.
For check this, you can use `go/ci/check/no-tidy`. It runs `go mod tidy` in 
each directory and if after run we have diff exit with non zero code.

## Using

Add `./makefile.inc` in your project and just add to your own `Makefile` next line:

```Makefile
include makefile.inc/versions.mk makefile.inc/bin.mk makefile.inc/duration.mk makefile.inc/golang.mk 
```

After it you can use all targets descrebes above in your `Makefile` or direcly run with make.

Also, we recommended to add to your `.gitignore` file content of our [.gitignore](.gitignore)

### Github workflow

We also provide github workflow example for checking pull-requests. 
See it in [./github-workflows/check_pull_request.yml](./github-workflows/check_pull_request.yml).
To use, copy workflow in `.github/workflows` directory.
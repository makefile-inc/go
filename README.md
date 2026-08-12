# makefile-go

Includes for Makefile for go operations like lint, test, build.

## Dependencies

Uses https://github.com/makefile-inc/common

Please [show](https://github.com/makefile-inc/common#dependencies) for install deps. 

## Install

### Manual

You can copy all files in your own repo (for example in subdir `makefile-go`) 
and include in root Makefile in the next way:

```Makefile
include $(CURDIR)/makefile-go/include.mk.inc
```

### As submodule

Add submodule:

```bash
git submodule add git@github.com:makefile-inc/go.git makefile-go
```

Checkout to target version:

```bash
pushd .
cd makefile-go
git fetch -a && git checkout v0.5.0
git submodule update --recursive --init 
popd
```

Include in root Makefile in the next way:

```Makefile
include $(CURDIR)/makefile-go/include.mk.inc
```

#### WARNINGS
- **WARNING! `makefile-go/include.mk.inc` include `https://github.com/makefile-inc/common` from your own submodule!
  If you are using another version of `https://github.com/makefile-inc/common` you can remove your include and use version of go!
  It is limitation of `make`.**
- **WARNING! If you use submodule and github actions, add to checkout action checkout submodules `submodules: "recursive"`, like:**
```yaml
...
    steps:
      - &checkout_step
        name: Checkout
        uses: actions/checkout@v6.0.2
        with:
          fetch-depth: 0
          submodules: "recursive"
          ref: ${{ github.event.pull_request.head.sha }}
...
```

## Update as submodule

```bash
cd makefile-go
git fetch -a && git checkout v0.5.0
git submodule update --recursive
popd
```

## Post install/update

Please add to `.gitignore` all entries from this repository `.gitignore` and from https://github.com/makefile-inc/common 

and run `make go/check/gitignore`.

Because targets generate some files which do not commit to git repo.

## Pre-definitions

It is include all variables and pre-definitions from [makefile.inc/common](https://github.com/makefile-inc/common#pre-definitions).

### Variables

- `GO_LANG_VERSION` - minor version (like `1.26`) of go usage.
  You can redeclare it before include or pass to `make` command as make parameter (env var)
  Also you can pass version with patch.
- `GOLANGCI_VERSION` - version for [golangci-lint](https://github.com/golangci/golangci-lint).
   You can redeclare it before include or pass to `make` command as make parameter (env var)
- `GOFUMPT_VERSION` - version for [gofumt](https://github.com/mvdan/gofumpt). 
   You can redeclare it before include or pass to `make` command as make parameter (env var)
- `GOLANGCI_BIN` - name of `golangci` binary: `golangci-lint`
- `GOFUMPT_BIN` - name of `gofumt` binary: `gofumpt`
- `GOLANGCI_BIN_FULL` - full path of `golangci` binary: `$(BINARIES_PATH)/$(GOLANGCI_BIN)`
- `GOFUMPT_BIN_FULL` - full path of `golangci` binary: `$(BINARIES_PATH)/$(GOFUMPT_BIN)`
- `GO_TESTS_TMP_DIR` - full path of temporary directory for test targets: `$(CURDIR)/.tmp-go-tests`.

### Definitions

- `FIND_GO_MODULES_CMD` - command for finding go modules inside `$(CURDIR)`.

  Example:
  ```Makefile
  include *.mk
  go-mods/print:
		@for ii in $$(${FIND_GO_MODULES_CMD}); do \
  		echo "Find go module in $$ii"; \
  	done
  ```

## Targets

### Install third-party binaries

- `install/go/golangci-lint` - [golangci-lint](https://github.com/golangci/golangci-lint) of version `GOLANGCI_VERSION`
- `install/go/gofumpt` - [gofumt](https://github.com/mvdan/gofumpt) of version `GOFUMPT_VERSION`.

### Checks

- `check/installed/go` - check that `go` installed and check golang version from `GO_LANG_VERSION`
- `go/check/gitignore/itself` - check that `.gitignore` in `makefile.inc/go` up to date with `makefile.inc/common`
- `go/check/gitignore` - check that `.gitignore` up to date with `makefile.inc/go`. Can be used in your repo.
- `go/check/license` - check that all `.go` files contains license header:
  
  ```go
  // Copyright YEAR
  // license that can be found in the LICENSE file.
  ```

  Using `common/license/check` target. If you need customize license check, see target `common/license/check` help. 

### Tidy

- `go/tidy` - find all go modules and run `go mod tidy` for them.
- `go/check/no-tidy` - run `go mod tidy` for all go modules and check that runs no produce diff.
  Useful for CI-checks before run tests and build

### Lint

- `go/lint` - lint `go` code with `golangci-lint`. Use `$(CURDIR)/.golangci.yaml` config. Find all do modules and lint for each.

  Params:
  - `RUN_FIX`=*true* - if passed run lint with fix problems. By default: no fix

- `go/lint/fix` - run `go/lint` with fix.

### Tests

- `.tmp-go-tests` - create tmp dir `$(CURDIR)/.tmp-go-tests` for output tests results. Needs for pretty print tests results
- `go/test` - run `go test` for all go modules and pretty print tests results.
  
  Params:
  - `GO_TEST_RACE`=*true* - run tests with `-race` flag. By default: run without race
  - `GO_TEST_FORCE_RESTART`=*true* - force rerun tests without using cache. By default: run with cache
  - `GO_TEST_PARALLEL`=*NUMBER* - run parallel tests packages. 
	   For disable parallelism pass `GO_TEST_PARALLEL=1`.
	   By default: use default `go test` parallelism mechanics.

  As you known, often heavy to find which test was failed in output of `go test`.

  Target output tests results in `json-format` for every go module to tmp file in  `$(CURDIR)/.tmp-go-tests` directory 
  
  with suffix `*.tst.res`, also output on screen default output. 
  
  After run tests for directory, targets check tests was failed or not. 
  
  If passed - remove file. If failed keep file. Also save duration of tests run.
  
  After runs tests for all go modules, target pretty-print output for all failed tests with red color.

  After print all outputs, print all failed tests in order by counts of `/` in tests.

  Output will like as in this example:
  ```
  --- Run tests in /home/nick/src/makefile.inc/tests-go ---
  === RUN   TestOK
  === RUN   TestOK/Ok_test_first
      main_test.go:10: First
  === RUN   TestOK/Ok_test_second
      main_test.go:14: Second
  --- PASS: TestOK (0.00s)
      --- PASS: TestOK/Ok_test_first (0.00s)
      --- PASS: TestOK/Ok_test_second (0.00s)
  === RUN   TestFailFirst
  === RUN   TestFailFirst/Fail_test_first
      main_test.go:23: Fail First
  --- FAIL: TestFailFirst (0.00s)
      --- FAIL: TestFailFirst/Fail_test_first (0.00s)
  === RUN   TestOKAnother
  === RUN   TestOKAnother/Another_Ok
      tags_test.go:7: Another
  --- PASS: TestOKAnother (0.00s)
      --- PASS: TestOKAnother/Another_Ok (0.00s)
  FAIL
  FAIL    github.com/makefile-inc/tests-go        0.002s
  === RUN   TestFailSecond
  === RUN   TestFailSecond/Fail_test_first
      var_test.go:13: Fail First
  --- FAIL: TestFailSecond (0.00s)
      --- FAIL: TestFailSecond/Fail_test_first (0.00s)
  === RUN   TestOKPkg
  === RUN   TestOKPkg/Ok_test_pkg
      var_test.go:20: OK pkg
  --- PASS: TestOKPkg (0.00s)
      --- PASS: TestOKPkg/Ok_test_pkg (0.00s)
  FAIL
  FAIL    github.com/makefile-inc/tests-go/pkg    0.002s
  /home/nick/src/makefile.inc/tests-go tests failed!
  --- Run tests in /home/nick/src/makefile.inc/tests-go/example ---
  === RUN   TestOK
  === RUN   TestOK/Ok_test_first
      main_test.go:10: First
  === RUN   TestOK/Ok_test_second_example
      main_test.go:14: Second
  --- PASS: TestOK (0.00s)
      --- PASS: TestOK/Ok_test_first (0.00s)
      --- PASS: TestOK/Ok_test_second_example (0.00s)
  === RUN   TestFailExample
  === RUN   TestFailExample/Fail_test_example
      main_test.go:23: Fail example
  --- FAIL: TestFailExample (0.00s)
      --- FAIL: TestFailExample/Fail_test_example (0.00s)
  FAIL
  FAIL    github.com/makefile-inc/tests-go/example        0.001s
  /home/nick/src/makefile.inc/tests-go/example tests failed!
  In "/home/nick/src/makefile.inc/tests-go" tests unsuccessful in 00.230660s
  --- Unsuccessful test TestFailFirst/Fail_test_first ---
  === RUN   TestFailFirst/Fail_test_first
      main_test.go:23: Fail First
      --- FAIL: TestFailFirst/Fail_test_first (0.00s)
  --- Unsuccessful test TestFailFirst ---
  === RUN   TestFailFirst
  --- FAIL: TestFailFirst (0.00s)
  --- Unsuccessful test TestFailSecond/Fail_test_first ---
  === RUN   TestFailSecond/Fail_test_first
      var_test.go:13: Fail First
      --- FAIL: TestFailSecond/Fail_test_first (0.00s)
  --- Unsuccessful test TestFailSecond ---
  === RUN   TestFailSecond
  --- FAIL: TestFailSecond (0.00s)
  In "/home/nick/src/makefile.inc/tests-go/example" tests unsuccessful in 00.145806s
  --- Unsuccessful test TestFailExample/Fail_test_example ---
  === RUN   TestFailExample/Fail_test_example
      main_test.go:23: Fail example
      --- FAIL: TestFailExample/Fail_test_example (0.00s)
  --- Unsuccessful test TestFailExample ---
  === RUN   TestFailExample
  --- FAIL: TestFailExample (0.00s)
  Tests FAILED in 00.398177s

  Unsuccessful tests:
  TestFailFirst
  TestFailSecond
  TestFailExample
  TestFailFirst/Fail_test_first
  TestFailSecond/Fail_test_first
  TestFailExample/Fail_test_example
  ```

  Output for failed test can be found by pattern: 
  
  `-- Unsuccessful test TEST_NAME` 

  like `-- Unsuccessful test TestFailFirst/Fail_test_first`.

  For all failed modules before outputs of tests target will print message:

  `In "$(CURDIR)/PATH_TO_MODULE" tests unsuccessful in DURATION`.

  If all tests passed, target output all modules when tests ran with duration
  and output total duration, like:
  ```
  Tests in '/home/nick/src/makefile.inc/tests-go' passed in 00.070729s
  Tests in '/home/nick/src/makefile.inc/tests-go/example' passed in 00.068966s
  All tests passed in 00.153546s
  ```
  
  Also, before run tests in module target print message like:
  ```
  --- Run tests in /home/nick/src/makefile.inc/tests-go/example ---
  ```

- `go/test/force` - force re-run tests (run `go/test` with `GO_TEST_FORCE_RESTART`)
- `go/test/race` - run race tests (run `go/test` with `GO_TEST_FORCE_RESTART` and `GO_TEST_RACE`)

### Build apps

Next targets build application with `go build` command.
Targets uses [common](https://github.com/makefile-inc/common#build) build targets
for generating binary name. All binaries will output in `BUILD_PATH` dir.
This dir can be redeclared with `SET_BUILD_PATH` `make` param (env). 

All targets take next parameters:
- `PROJECT_NAME`=*NAME* - name of project (prefix of binary). Required
- `GO_TARGET`=*PKG_OR_FILE* - path to package or go file to build. Required
- `GO_TARGET_MODULE`=*DIR* - if passed will cd to passed directory for build. Optional
- `GO_BUILD_TAGS`=*TAGS...* - comma-separated build tags. Optional
- `GO_BUILD_VARIABLES`=*VARIABLES...* - `//||`-separated variables to set to binary. Optional. See examples below
- `GO_BUILD_DYNAMIC`=*true* - if passed build dynamic binary with `CGO`. By default will build static-linked binary

#### Build targets

- `go/build/current` - build go app for current os and arch
- `go/build/linux` - build go app for linux os and current arch
- `go/build/linux/all` - build go app for linux for all arch
- `go/build/mac` - build go app for linux os and arm arch
- `go/build/mac/all` - build go app for all arch
- `go/build/all` - build go app for mac and linux for all arch

#### Cleanup build binaries

Use `clean/build` for remove all built binaries.

#### Caveats

**WARNING!** If you are using chan target depend on one build target like:
```Makefile
build-dev: export GO_BUILD_TAGS = dev
build-dev: go/build/current

build-prod: export GO_BUILD_TAGS = prod
build-prod: go/build/current

## THIS IS INCORRECT!
build-all: build-dev build-prod
```
you should use recursive `make` call for chain target like:
```Makefile
build-dev: export GO_BUILD_TAGS = dev
build-dev: go/build/current

build-prod: export GO_BUILD_TAGS = prod
build-prod: go/build/current

## This correct
build-all:
	@$(MAKE) build-dev
	@$(MAKE) build-prod
```
because `make` will cache `go/build/current` and you build only dev binary.

#### Build examples

- with multiple tags
  ```Makefile
  include *.mk
  
  export GO_TARGET = .

  build/tags: export PROJECT_NAME = main-tags
  build/tags: export GO_BUILD_TAGS = prod,minimal
  build/tags: go/build/current
  ```

- with multiple build variables
  ```Makefile
  include *.mk

  export GO_TARGET = .

  define BUILD_VARIABLES_ALL
  main.first=first set//||\
  main.second=second//||\
  github.com/makefile-inc/tests-go/pkg.PkgVar= pkg set
  endef
  
  build/vars: export PROJECT_NAME = main-vars
  build/vars: export GO_BUILD_VARIABLES = ${BUILD_VARIABLES_ALL}
  build/vars: go/build/current
  ```
- with one variable
  ```Makefile
  include *.mk
  
  export GO_TARGET = .

  define BUILD_VARIABLES_FIRST
  main.first=first set
  endef
  
  build/vars: export PROJECT_NAME = main-var-first
  build/vars: export GO_BUILD_VARIABLES = ${BUILD_VARIABLES_FIRST}
  build/vars: go/build/current
  ```
- all-in
  ```Makefile
  include *.mk

  export GO_TARGET = .

  define BUILD_VARIABLES_CUSTOMER
  main.customer=big-client
  endef

  .PHONY: build/api build/migration build/app
  
  build/api: export PROJECT_NAME = api-server
  build/api: export GO_TARGET_MODULE = api/cmd
  build/api: export GO_BUILD_TAGS = prod,minimal
  build/api: export GO_BUILD_VARIABLES = ${BUILD_VARIABLES_CUSTOMER}
  build/api: go/build/current

  build/migration: export PROJECT_NAME = migration
  build/migration: export GO_TARGET_MODULE = migration/cmd
  build/migration: export GO_BUILD_DYNAMIC = true
  build/migration: export GO_BUILD_TAGS = prod
  build/migration: go/build/current

  build/app:
  	@$(MAKE) build/api
		@$(MAKE) build/migration
  ```

### Cleanup

- `clean/go` - remove `gofumpt` and `golangci-lint` binaries and tmp test dir and binaries produced by build
  
  Params:
  - `REMOVE_COMMON`=*true* - if passed remove binaries for https://github.com/makefile-inc/common.git
	  By default: no remove.

## Github actions

### Test and lint

#### Description

Test go code with https://github.com/makefile-inc/go
This action does not build any binaries. If you need check build binary
before or after testing use your own steps. 
By default, action will checkout repo on github.event.pull_request.head.sha
if handle `PullRequestEvent` with `submodules: "recursive"` option.

Do next checks:
- `go/check/license` (if need call customize check you can redeclare target with parameter `check_license` or disable with pass `false` to `check_license`)
- `go/check/gitignore`
- `go/check/no-tidy`
- `go/test`
- `go/test/race` (if need)
- `go/lint`

#### Deps actions

Action uses:
- [actions/checkout](https://github.com/actions/checkout/tree/3d3c42e5aac5ba805825da76410c181273ba90b1) - v7.0.1
- [actions/setup-go](https://github.com/actions/setup-go/tree/b7ad1dad31e06c5925ef5d2fc7ad053ef454303e) - v7.0.0
- [name212/action-cleanup](https://github.com/name212/action-cleanup/tree/377b123439a8ed3ada3d9553857d2a0a7bc3fcf9) - v2

#### Usage

```yaml
- uses: makefile-inc/go/.github/actions/test@v0.5.0
  with:
    # Go version for actions/setup-go like `1.26.x`.
    # If do not need to setup go pass empty string.
    # Optional
    go_version: '1.26.x'
    
    # Checkout repo. 
    # You can pass next values:
    # - '_pull_request_ref_' - will checkout on `github.event.pull_request.head.sha` if handle `PullRequestEvent` 
    #   with `submodules: "recursive"` option.
    #   If event is not `PullRequestEvent` or `github.event.pull_request.head.sha` is empty, will exit with error
    # - '' - empty string disable, pass for example run tests on tags.
    #   In this case you need checkout manually before run action
    #   with `submodules: "recursive"` option!
    #   It is default, because we suppose that you are using action with submodule.
    # - 'ref' - non-empty string represents as ref in github repo.
    #   Will checkout with `submodules: "recursive"` option.
    # Optional
    checkout: ''

    # Check .gitignore for repo for in sync with makefile include repo.
    # Pass 'false' to disable.
    # Optional
    check_gitignore: 'true'

    # Check check license header with make target.
    # By default, use `go/check/license` target.
    # Pass 'false' to disable.
    # Optional
    check_license: 'go/check/license'
  
    # Run tests with `-race` flag
    #  Values:
    #  - no - no run race tests (default)
    #  - with_tests - run race tests after run tests without `-race`
    #  - without_tests - run race tests without no race tests
    # Optional
    run_race_tests: 'no'
    
    # Run tests in parallel (by default).
    # Pass 'false' to run tests with flag `-p 1`
    # Optional
    parallel_tests: 'true'
    
    # Add envs to run tests.
    # Should be in `.env` format like: 
    #   # disable e2e
    #   ENABLE_E2E=false
    #   # enable integration 
    #   ENABLE_INTEGRATION=true
    # Optional
    tests_envs: ''
    
    # Comma-separated tags for run tests.
    # Optional
    tests_tags: ''
```

#### Examples

- Pull request check workflow

```yaml
name: Check pull request
on:
  pull_request:
    types:
      - opened
      - synchronize
      - reopened
jobs:
  tests:
    name: "Tests"
    runs-on: ubuntu-latest
    timeout-minutes: 10

    steps:
    - name: Run tests
      uses: makefile-inc/go/.github/actions/test@v0.5.0
      with:
        checkout: "_pull_request_ref_"
        run_race_tests: "with_tests"
        parallel_tests: "false"
        tests_tags: "test_tag_first,test_tag_second"
        tests_envs: |
          # Pass event with comment
          BLAH_ENV=passed
```
- Pull request check workflow for library using submodule dir

```yaml
name: Check pull request
on:
  pull_request:
    types:
      - opened
      - synchronize
      - reopened
jobs:
  tests:
    name: "Tests"
    runs-on: ubuntu-latest
    timeout-minutes: 10

    steps:
    - name: Run tests
      uses: name212/action-dynamic-uses@dc77a3349fecbd50c85ee651868ac03444af877a # v3
      with:
        uses: 'dir:makefile-go/.github/actions/test'
        # Checkout before usage
        checkout: ${{ github.event.pull_request.head.sha }}
        with:
          run_race_tests: "with_tests"
          parallel_tests: "false"
```

### Release

Create release for go-application.
For create/update release you can use your own token with pass via
`inputs.token`. For successful upload, token or job should set next permissions:

```yaml
- contents: write
```

Example for job:
```yaml
jobs:
  release:
    runs-on: ubuntu-latest
    # Define required permissions here
    permissions:
      contents: write
    steps:
    - name: Release
      uses: makefile-inc/go/.github/actions/release@v0.5.0
      with:
        token: ${{ secrets.GITHUB_TOKEN }}
```

Do next:
- check that release not exists or in draft and not immutable
  to prevent break another releases.
- if release not exists prepare release notices file
- checkout to target ref to build
- creates temp build dir with random suffix
- build code with `make` target passed in `inputs.build_target`. Pass to target :
  - `PROJECT_NAME` as `inputs.project` as env
  - `SET_BUILD_PATH` as created build dir as env
- test code (if `inputs.tests_envs` passed created envs file with random suffix)
  you can disable tests with pass `inputs.run_tests: 'no'`
- if additional artifacts script or target passed:
  - creates temp dir for artifacts
  - pass created temp dir to script or make via `RELEASE_GO_ARTIFACTS_DIR` env
- creates temp release artifacts dir with random prefix
  and prepare release artifact with `make` target `common/release` 
- create release with `inputs.release_name` in draft. 
  If release already created, only upload artifacts.
  It helpful for use multiple action calls, for example 
  Build api-server and migration.
- cleanup all created files and dirs

#### Deps actions

Action uses:
- [actions/checkout](https://github.com/actions/checkout/tree/3d3c42e5aac5ba805825da76410c181273ba90b1) - v7.0.1
- [actions/setup-go](https://github.com/actions/setup-go/tree/b7ad1dad31e06c5925ef5d2fc7ad053ef454303e) - v7.0.0
- [name212/action-cleanup](https://github.com/name212/action-cleanup/tree/377b123439a8ed3ada3d9553857d2a0a7bc3fcf9) - v2

#### Usage

```yaml
- uses: makefile-inc/go/.github/actions/release@v0.5.0
  with:
    # Go version for actions/setup-go like `1.26.x`.
    # If do not need to setup go pass empty string.
    # Optional
    go_version: '1.26.x'
    
    # Checkout repo to ref: branch, commit or tag
    # Required
    target_ref: 'main'

    # Token for create release. 
    # Token or job should set next permissions:
    # - contents: write
    # Required.
    # Example for job:
    # jobs:
    #   release:
    #     runs-on: ubuntu-latest
    #     permissions:
    #       contents: write
    #     steps:
    #     - name: Release
    #       uses: makefile-inc/go/.github/actions/release@v0.5.0
    #       with:
    #         token: ${{ secrets.GITHUB_TOKEN }}
    token: 'gha-efirjifjrifrjfr'

    # Project name (binary target) to build.
    # Passed as env `PROJECT_NAME` to build and prepare additional artifacts.
    # Required.
    project: 'migration'

    # `make` target for build.
    # Step creates build dir and pass to target via `SET_BUILD_PATH` env.
    # Also, step pass `inputs.project` to target via `PROJECT_NAME` env.
    # If need add build tags, variables or module path, please use  
    # `GO_TARGET`, `GO_TARGET_MODULE`, `GO_BUILD_TAGS`, `GO_BUILD_VARIABLES`, `GO_BUILD_DYNAMIC`
    # params for target in makefile or pass via `env`.
    # Required.
    build_target: 'release/migration'

    # Bash script or `make` target for prepare artifact.
    # Step pass next envs for preparation:
    # - `RELEASE_GO_ARTIFACTS_DIR` - dir for save artifact.
    # If you need to use `make` target pass param with prefix `make::`
    # Optional.
    prepare_artifacts: |
      cp "README.md" "$RELEASE_GO_ARTIFACTS_DIR"
      cp "LICENSE" "$RELEASE_GO_ARTIFACTS_DIR"

    # Name of release. Should be valid tag name like `v1.0.0`
    # Required
    release_name: 'v1.0.0'

    # Release notes in markdown format. 
    # If you want to use file, pass param with prefix `md_file::`
    # Required
    release_notes: |
      First release.
      Add:
      - Migration to data base to new schema
      Fix:
      - Connection string to db

    # Run tests:
    # - 'yes' - run tests without race (default)
    # - 'race' - run tests with race
    # - 'no' - skip run tests
    # Optional.
    run_tests: 'yes'

    # Use `go test` default parallelism mechanics (by default).
    # Pass 'false' to run tests with flag `-p 1`.
    # Optional.
    tests_parallelism: 'true'

    # Add envs to run tests.
    # Should be in `.env` format like: 
    #   # disable e2e
    #   ENABLE_E2E=false
    #   # enable integration 
    #   ENABLE_INTEGRATION=true
    # Optional
    tests_envs: ''

    # Comma-separated tags for run tests.
    # Optional
    tests_tags: ''
```

#### Examples

- Release one app manual without

```yaml
on:
  workflow_dispatch:
    inputs:
      tag:
        description: 'Tag for create release'
        required: true
        type: string
      
      notes:
        description: 'Release notes'
        required: true
        type: string
      
jobs:
  release:
    name: "Release application"
    runs-on: ubuntu-latest
    timeout-minutes: 10
    permissions:
      contents: write

    steps:
    - name: Release
      uses: makefile-inc/go/.github/actions/release@v0.5.0
      with: |
        token: ${{ secrets.GITHUB_TOKEN }}
        target_ref: 'main'
        project: "app"
        build_target: "release/app"
        run_tests: "race"
        release_name: ${{ steps.release_name.outputs.tag }}
        release_notes: ${{ inputs.notes }}
```

- Release one app on tag push with prepared notice in repo without tests

```yaml
on:
  push:
    tags:
      - v[0-9]+.[0-9]+.[0-9]+
      
jobs:
  release:
    name: "Release application"
    runs-on: ubuntu-latest
    timeout-minutes: 10
    permissions:
      contents: write

    steps:
    - name: Release name
      id: release_name
      env:
        REF: ${{ github.event.push.ref }}
      run: |
        tag_prefix="refs/tags/"
        out_ref="${REF#"$tag_prefix"}
        echo "tag=${out_ref}" >> "$GITHUB_OUTPUT"
    - name: Release
      uses: makefile-inc/go/.github/actions/release@v0.5.0
      with: |
        token: ${{ secrets.GITHUB_TOKEN }}
        target_ref: ${{ steps.release_name.outputs.tag }}
        project: "app"
        build_target: "release/app"
        run_tests: "no"
        release_name: ${{ steps.release_name.outputs.tag }}
        release_notes: "md_file::./CHANGELOGS/v${{ inputs.tag }}"
```

- Release multiple apps on branch with artifacts and prepared notice
  uses submodule action.

```yaml
on:
  push:
    branches:
      - 'release-[0-9]+'
      
jobs:
  release:
    name: "Release application"
    runs-on: ubuntu-latest
    timeout-minutes: 10
    permissions:
      contents: write

    steps:
    - name: Release name
      id: release_name
      env:
        REF: ${{ github.event.push.ref }}
      run: |
        branch_ref_prefix="refs/heads/"
        branch_prefix="release-"
        number="${REF#"$branch_ref_prefix"}
        number="${out_ref#"$branch_prefix"}
        tag="v${number}"
        notes_file="md_file::./CHANGELOGS/${tag}"

        echo "tag=${tag}" >> "$GITHUB_OUTPUT"
        echo "notes_file=${notes_file}" >> "$GITHUB_OUTPUT"
        echo "ref=${REF}" >> "$GITHUB_OUTPUT"
    - name: Release server
      uses: name212/action-dynamic-uses@dc77a3349fecbd50c85ee651868ac03444af877a # v3
      with:
        uses: 'dir:makefile-go/.github/actions/release'
        with: |
          token: ${{ secrets.GITHUB_TOKEN }}
          target_ref: ${{ steps.release_name.outputs.ref }}
          project: "server"
          build_target: "release/server"
          release_name: ${{ steps.release_name.outputs.tag }}
          release_notes: ${{ steps.release_name.outputs.notes_file }}
          prepare_artifacts: |
            cp "README.md" "$RELEASE_GO_ARTIFACTS_DIR"
            cp "LICENSE" "$RELEASE_GO_ARTIFACTS_DIR"
          tests_tags: "server"
    - name: Release migration
      uses: name212/action-dynamic-uses@dc77a3349fecbd50c85ee651868ac03444af877a # v3
      with:
        uses: 'dir:makefile-go/.github/actions/release'
        env:
        with: |
          go_version: "" # do not setup second time
          target_ref: ${{ steps.release_name.outputs.ref }}
          token: ${{ secrets.GITHUB_TOKEN }}
          project: "migration"
          build_target: "release/migration"
          release_name: ${{ steps.release_name.outputs.tag }}
          release_notes: ${{ steps.release_name.outputs.notes_file }}
          prepare_artifacts: "make::artifacts/migration"
          tests_parallelism: "false"
          tests_tags: "migration"
          tests_envs: |
            # Enable tests for migration name
            MIGRATION_NAME="user-icons"
```

## Full example Makefile

```Makefile
include *.mk

export GO_TARGET = .

define BUILD_VARIABLES_CUSTOMER
main.customer=big-client
endef

.PHONY: build/api build/migration build/app ci/checks ci/build

build/api: export PROJECT_NAME = api-server
build/api: export GO_TARGET_MODULE = api/cmd
build/api: export GO_BUILD_TAGS = prod,minimal
build/api: export GO_BUILD_VARIABLES = ${BUILD_VARIABLES_CUSTOMER}
build/api: go/build/current

build/migration: export PROJECT_NAME = migration
build/migration: export GO_TARGET_MODULE = migration/cmd
build/migration: export GO_BUILD_DYNAMIC = true
build/migration: export GO_BUILD_TAGS = prod
build/migration: go/build/current

build/app:
	@$(MAKE) build/api
	@$(MAKE) build/migration

ci/checks: go/check/gitignore go/check/no-tidy go/lint go/test
ci/build: ci/checks build/app
```
## Targets test repo

https://github.com/makefile-inc/tests-go
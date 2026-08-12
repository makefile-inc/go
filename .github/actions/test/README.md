### Test and lint go code

#### Description

Test go code with https://github.com/makefile-inc/go
This action does not build any binaries. If you need check build binary
before or after testing use your own steps. 
By default, action will checkout repo on github.event.pull_request.head.sha
if handle `PullRequestEvent` with `submodules: "recursive"` option.

Do next checks:
- `go/check/license`
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

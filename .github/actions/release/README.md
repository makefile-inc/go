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

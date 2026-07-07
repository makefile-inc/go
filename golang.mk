GOLANGCI_BIN          = golangci-lint
GOFUMPT_BIN           = gofumpt

GOLANGCI_BIN_FULL     = $(BINARIES_PATH)/$(GOLANGCI_BIN)
GOFUMPT_BIN_FULL      = $(BINARIES_PATH)/$(GOFUMPT_BIN)

GO_TESTS_TMP_DIR      = $(abspath $(CURDIR)/tmp-go-tests)

# FIND_GO_MODULES_CMD - command for finding go modules inside $(CURDIR)
# DO NOT in $(call ...)
# Example:
#   include *.mk
#   go-mods/print:
#	      @for ii in $$(${FIND_GO_MODULES_CMD}); do \
#	          echo "Find go module in $$ii"; \
#         done
define FIND_GO_MODULES_CMD
find $(CURDIR) -type f -name "go.mod" -printf "%h\n" | sort -u
endef

##@ Go. Checks and download deps

check/installed/go: ## Check that go installed and check golang version (from GO_LANG_VERSION)
	@command -v go > /dev/null
	@${INCLUDE_ECHO} \
	expected_ver="$(GO_LANG_VERSION)"; \
	if [ -z "$$expected_ver" ]; then \
		exit 0; \
	fi; \
	if ! go_ver="$$(go version)"; then \
		exit_with_err "Cannot get go version"; \
	fi; \
	if ! grep -q "go$$expected_ver" <<<"$$go_ver"; then \
		exit_with_err "Incorrect go version '$$go_ver' Should be match to 'go$$expected_ver'"; \
	fi; \
	exit 0

_GO_ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

go/check/gitignore/itself: export GITIGNORES_WITH_REQUIRED_RULES = $(_GO_ROOT_DIR)/makefile-common/.gitignore
go/check/gitignore/itself: common/git/check/gitignore ## Check that .gitignore in makefile.inc/go up to date with makefile.inc/common 

go/check/gitignore: ## Check that .gitignore up to date with makefile.inc/common and makefile.inc/go
	@${INCLUDE_ECHO} \
	to_check=( \
		"$(_GO_ROOT_DIR)/makefile-common/.gitignore" \
		"$(_GO_ROOT_DIR)/.gitignore" \
	); \
	failed=(); \
	for ck in "$${to_check[@]}"; do \
		echo_info "Check gitignore for $$ck"; \
		if ! $(MAKE) common/git/check/gitignore GITIGNORES_WITH_REQUIRED_RULES="$$ck"; then \
			failed+=("$$ck"); \
		fi; \
	done; \
	if [ "$${#failed[@]}" -eq "0" ]; then \
		exit 0; \
	fi; \
	echo_err "Gitignore not contains items from:"; \
	for fl in "$${failed[@]}"; do \
		echo_err "  $$fl"; \
	done; \
	exit 1

install/go/gofumpt: export INSTALL_BIN_NAME = $(GOFUMPT_BIN)
install/go/gofumpt: export INSTALL_BIN_VERSION = $(GOFUMPT_VERSION)
install/go/gofumpt: export INSTALL_BIN_VERSION_ARG = -version
install/go/gofumpt: export INSTALL_BIN_URL = https://github.com/mvdan/gofumpt/releases/download/v@BIN_VER@/gofumpt_v@BIN_VER@_@BIN_OS@_@BIN_ARCH@
install/go/gofumpt: ## gofumpt https://github.com/mvdan/gofumpt
	@$(MAKE) install/binary

install/go/golangci-lint: export INSTALL_BIN_NAME = $(GOLANGCI_BIN)
install/go/golangci-lint: export INSTALL_BIN_VERSION_ARG = --version
install/go/golangci-lint: export INSTALL_BIN_VERSION = $(GOLANGCI_VERSION)
install/go/golangci-lint: check/installed/curl ## golangci-lint https://github.com/golangci/golangci-lint
	@function get_lint() { \
		local version="$$1"; \
		local bin_name="$$4"; \
		local bin_dir="$$6"; \
		set -Eeuo pipefail; \
		curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | BINDIR="$$bin_dir" BINARY="$$bin_name" bash -s -- "v$$version"; \
	}; \
	${INCLUDE_CHECK_BINARY} \
	if ! check_and_get_bin get_lint; then \
		exit 1; \
	fi

##@ Go. Linting

go/lint: check/installed/go install/go/golangci-lint ## Lint code with golangci-lint. Use $(CURDIR)/.golangci.yaml config. Find all do modules and lint for each
	@##~ RUN_FIX=true - run lint with fix problems. By default: no fix
	@${INCLUDE_ECHO} \
	full_cfg="$(CURDIR)/.golangci.yaml"; \
	if [ ! -f "$$full_cfg" ]; then \
		exit_with_err "config '$$full_cfg' is not present!"; \
	fi;\
	fix_arg=""; \
	if [ -n "$$RUN_FIX" ]; then \
		fix_arg="--fix"; \
	fi; \
	full_cfg="$$(realpath .golangci.yaml)"; \
	full_lint_bin="$(GOLANGCI_BIN_FULL)"; \
	failed=(); \
	for ii in $$(${FIND_GO_MODULES_CMD}); do \
		pushd . > /dev/null; \
		full_path="$$(realpath "$$ii")"; \
		echo "--- Run lint in $$full_path ---"; \
		if ! cd "$$full_path"; then \
			exit_with_err "Cannot cd to $$full_path"; \
		fi; \
		if ! "$$full_lint_bin" run ./... -c "$$full_cfg" $$fix_arg; then \
			echo_err "Lint in $$full_path failed!"; \
			failed+=("$$full_path"); \
		fi; \
		popd > /dev/null; \
	done; \
	if [ "$${#failed[@]}" -eq "0" ]; then \
		exit 0; \
	fi; \
	echo_err "Code not linted in:"; \
	for fl in "$${failed[@]}"; do \
		echo_err "  $$fl"; \
	done; \
	exit 1

go/lint/fix: export RUN_FIX = true
go/lint/fix: go/lint ## Run go/lint with fix

##@ Go. Tidy

go/tidy: check/installed/go ## Find all go modules and run go mod tidy
	@${INCLUDE_ECHO} \
	failed=(); \
	for ii in $$(${FIND_GO_MODULES_CMD}); do \
		pushd . > /dev/null; \
		full_path="$$(realpath "$$ii")"; \
		if ! cd "$$full_path"; then \
			exit_with_err "Cannot cd to $$full_path"; \
		fi; \
		echo_info "Run go mod tidy in $$full_path"; \
		if ! go mod tidy; then \
			echo_err "go mod tidy in $$full_path failed!"; \
			failed+=("$$full_path"); \
		fi; \
		popd > /dev/null; \
	done; \
	if [ "$${#failed[@]}" -eq "0" ]; then \
		exit 0; \
	fi; \
	echo_err "go mod tidy failed in:"; \
	for fl in "$${failed[@]}"; do \
		echo_err "  $$fl"; \
	done; \
	exit 1

go/check/no-tidy: export TARGET_NAME = go/tidy
go/check/no-tidy: export FILES_TO_CHECK = .*go.mod,.*go.sum
go/check/no-tidy: export HAS_DIFF_MSG = go mod tidy produce diff. Please run 'make go/tidy' and commit
go/check/no-tidy: common/git/check/has-diff ## Run go mod tidy for all go modules and check that runs no produce diff

##@ Go. Tests

tmp-go-tests: ## Create tmp dir ($(CURDIR)/tmp/go-tests) for output tests results. Needs for pretty print tests results
	@mkdir -p "$(GO_TESTS_TMP_DIR)"

go/test: check/installed/go install/jq tmp-go-tests ## Run go test for all go modules and pretty print tests results.
	@##~ GO_TEST_RACE=true - run tests with -race flag. By default: run without race
	@##~ GO_TEST_FORCE_RESTART=true - force rerun tests without using cache. By default: run with cache
	@##~ GO_TEST_PARALLEL=NUMBER - if passed run parallel tests packages. 
	@##~   For disable parallelism pass GO_TEST_PARALLEL=1
	@##~   By default: use default parallelism mechanics
	@${INCLUDE_ECHO} \
	race_arg=""; \
	if [ -n "$$GO_TEST_RACE" ]; then \
		echo_info "Run race tests..."; \
		race_arg="-race"; \
	fi; \
	force_restart_arg=""; \
	if [ -n "$$GO_TEST_FORCE_RESTART" ]; then \
		force_restart_arg="-count=1"; \
	fi; \
	parallel_arg=""; \
	if [ -n "$$GO_TEST_PARALLEL" ]; then \
		parallel_arg="-p $$GO_TEST_PARALLEL"; \
	fi; \
	jq_bin="$(JQ_BIN_FULL)"; \
	declare -A succeeded_durations; \
	failed_files=(); \
	declare -A failed_tests_to_files; \
	declare -A failed_durations; \
	start_all_micro="$$(${NOW_MICROSECONDS})"; \
	for ii in $$(${FIND_GO_MODULES_CMD}); do \
		file_nano="$$(date +"%s-%N")"; \
		out_file="$(GO_TESTS_TMP_DIR)/$${file_nano}-$${RANDOM}.tst.res"; \
		pushd . > /dev/null; \
		full_path="$$(realpath "$$ii")"; \
		echo_info "--- Run tests in $$full_path ---"; \
		if ! cd "$$full_path"; then \
			exit_with_err "Cannot cd to $$full_path"; \
		fi; \
		start_test_micro="$$(${NOW_MICROSECONDS})"; \
		is_failed=""; \
		go test $$force_restart_arg $$race_arg -json -v $$parallel_arg ./... | tee "$$out_file" | "$$jq_bin" -r 'if has("Output") then .Output else "" end' | grep -v '^$$'; \
		if [ "$${PIPESTATUS[0]}" != "0" ]; then \
			is_failed="true"; \
		fi; \
		end_test_micro="$$(${NOW_MICROSECONDS})"; \
		cur_test_duration="$$(${HUMAN_DURATION_MICROSECONDS} "$$start_test_micro" "$$end_test_micro")"; \
		if [ -n "$$is_failed" ]; then \
			failed_files+=("$$out_file"); \
			failed_tests_to_files["$$out_file"]="$$full_path"; \
			failed_durations["$$out_file"]="$$cur_test_duration"; \
			echo_err "$$full_path tests failed!"; \
		else \
			succeeded_durations["$$full_path"]="$$cur_test_duration"; \
			rm -f "$$out_file"; \
		fi; \
		popd > /dev/null; \
	done; \
	end_all_micro="$$(${NOW_MICROSECONDS})"; \
	all_duration="$$(${HUMAN_DURATION_MICROSECONDS} "$$start_all_micro" "$$end_all_micro")"; \
	for st in "$${!succeeded_durations[@]}"; do \
    	echo_info "Tests in '$$st' passed in $${succeeded_durations[$$st]}"; \
	done; \
	if [ "$${#failed_files[@]}" -eq 0 ]; then \
		echo_info "All tests passed in $$all_duration"; \
		exit 0; \
	fi; \
	failed_tests=""; \
	for fail_file in "$${failed_files[@]}"; do \
		echo_err "In \"$${failed_tests_to_files[$$fail_file]}\" tests unsuccessful in $${failed_durations[$$fail_file]}"; \
		fail_for_file="$$("$$jq_bin" -r 'select(.Action == "fail" and has("Test")) | .Test' "$$fail_file")"; \
		if [ -z "$$fail_for_file" ]; then \
			continue; \
		fi; \
		IFS=$$'\n' read -rd '' -a list_failed <<< "$$fail_for_file"; \
		for fail_test_name in "$${list_failed[@]}"; do \
			failed_tests+=$$'\n'; \
			failed_tests+="\"$$fail_test_name\""; \
			echo_err "--- Unsuccessful test $$fail_test_name ---"; \
			echo_err "$$("$$jq_bin" -r "select(has(\"Test\") and has(\"Output\") and .Test == \"$$fail_test_name\") | .Output" "$$fail_file" | grep -v '^$$')"; \
		done; \
		rm -f "$$fail_file"; \
	done; \
	echo_err "Tests FAILED in $$all_duration"; \
	if [ -n "$$failed_tests" ]; then \
		echo "";\
		echo_err "Unsuccessful tests:"; \
		echo_err "$$("$$jq_bin" -rs "flatten | sort_by(. | split(\"/\") | length - 1) | join(\"\n\")"<<<"$$failed_tests")"; \
		echo "";\
	fi; \
	exit 1

go/test/race: export GO_TEST_RACE = true
go/test/race: export GO_TEST_FORCE_RESTART = true
go/test/race: ## Run go test for all go modules with -force flag and force restart 
	@$(MAKE) go/test

go/test/force: export GO_TEST_FORCE_RESTART = true
go/test/force: ## Run go test for all go modules with force restart
	@$(MAKE) go/test

##@ Go. Build

export BUILD_TARGET = _go/build/target

_go/build/target:
	@${INCLUDE_ECHO} \
	${INCLUDE_SPLIT} \
	if [ -z "$$GO_TARGET" ]; then \
		exit_with_err "GO_TARGET not passed"; \
	fi; \
	if [[ -z "$$GO_BUILD_DYNAMIC" && -n "$$GO_ENABLE_CGO" ]]; then \
		exit_with_err "Conflict! GO_BUILD_DYNAMIC not passed and GO_ENABLE_CGO passed"; \
	fi; \
	ld_flags=""; \
	if [[ -z "$$GO_BUILD_DYNAMIC" ]]; then \
		ld_flags="-s -w -extldflags '-static'"; \
	fi; \
	if [ -n "$$GO_BUILD_VARIABLES" ]; then \
		if ! split_by "//||" split_vars "$$GO_BUILD_VARIABLES"; then \
			exit_with_err "Cannot split GO_BUILD_VARIABLES='$$GO_BUILD_VARIABLES'"; \
		fi; \
		for vr in "$${split_vars[@]}"; do \
			t_vr="$$(trim_spaces "$$vr")"; \
			if [ -z "$$t_vr" ]; then \
				continue; \
			fi; \
			if [ -n "$$ld_flags" ]; then \
				ld_flags="$${ld_flags} "; \
			fi; \
			ld_flags="$${ld_flags}-X $$t_vr"; \
		done; \
	fi; \
	build_args=("build"); \
	if [ -n "$$GO_BUILD_TAGS" ]; then \
		split_by_comma go_tags_parsed "$$GO_BUILD_TAGS"; \
		go_tags=""; \
		for tg in "$${go_tags_parsed[@]}"; do \
			t_tg="$$(trim_spaces "$$tg")"; \
			if [ -z "$$t_tg" ]; then \
				continue; \
			fi; \
			if [ -n "$$go_tags" ]; then \
				go_tags="$${go_tags},"; \
			fi; \
			go_tags="$${go_tags}$${t_tg}"; \
		done; \
		if [ -n "$$go_tags" ]; then \
			build_args+=("-tags=$$go_tags"); \
		fi; \
	fi; \
	if [ -n "$$ld_flags" ]; then \
		build_args+=("-ldflags"); \
		build_args+=("$$ld_flags"); \
	fi; \
	build_args+=("-o"); \
	build_args+=("$$OUT_BIN"); \
	build_args+=("$$GO_TARGET"); \
	cgo_en="0"; \
	if [ -n "$$GO_ENABLE_CGO" ]; then \
		cgo_en="1"; \
	fi; \
	build_str=""; \
	for ba in "$${build_args[@]}"; do \
		ba_t="$$ba"; \
		if [[ "$$ba" =~ [[:space:]] ]]; then \
    		ba_t="\"$$ba\""; \
		fi; \
		if [ -n "$$build_str" ]; then \
			build_str="$${build_str} "; \
		fi; \
		build_str="$${build_str}$${ba_t}"; \
	done; \
	echo_info "Build..."; \
	echo_info "  GOOS=\"$$BUILD_OS\" GOARCH=\"$$BUILD_ARCH\" CGO_ENABLED=\"$$cgo_en\" go $$build_str"; \
	GOOS="$$BUILD_OS" GOARCH="$$BUILD_ARCH" CGO_ENABLED="$$cgo_en" go "$${build_args[@]}"

go/build/current: build/current ## Build go app for current os and arch
	@##~ PROJECT_NAME=NAME - name of project. Required
	@##~ GO_TARGET=PKG_OR_FILE - path to package or go file to build. Required
	@##~ GO_BUILD_TAGS=TAGS... - comma-separated build tags. Optional
	@##~ GO_BUILD_VARIABLES=VARIABLES... - //||-separated variables to add to binary. Optional
	@##~ GO_BUILD_DYNAMIC=true - if passed build dynamic binary without CGO
	@##~ GO_ENABLE_CGO=true - if passed build binary with CGO

go/build/linux: build/linux ## Build go app for linux os and current arch
	@##~ PROJECT_NAME=NAME - name of project. Required
	@##~ GO_TARGET=PKG_OR_FILE - path to package or go file to build. Required
	@##~ GO_BUILD_TAGS=TAGS... - comma-separated build tags. Optional
	@##~ GO_BUILD_VARIABLES=VARIABLES... - //||-separated variables to add to binary. Optional
	@##~ GO_BUILD_DYNAMIC=true - if passed build dynamic binary without CGO
	@##~ GO_ENABLE_CGO=true - if passed build binary with CGO

go/build/linux/all: build/linux/all ## Build go app for linux for all arch
	@##~ PROJECT_NAME=NAME - name of project. Required
	@##~ GO_TARGET=PKG_OR_FILE - path to package or go file to build. Required
	@##~ GO_BUILD_TAGS=TAGS... - comma-separated build tags. Optional
	@##~ GO_BUILD_VARIABLES=VARIABLES... - //||-separated variables to add to binary. Optional
	@##~ GO_BUILD_DYNAMIC=true - if passed build dynamic binary without CGO
	@##~ GO_ENABLE_CGO=true - if passed build binary with CGO

go/build/mac: build/mac ## Build go app for linux os and arm arch
	@##~ PROJECT_NAME=NAME - name of project. Required
	@##~ GO_TARGET=PKG_OR_FILE - path to package or go file to build. Required
	@##~ GO_BUILD_TAGS=TAGS... - comma-separated build tags. Optional
	@##~ GO_BUILD_VARIABLES=VARIABLES... - //||-separated variables to add to binary. Optional
	@##~ GO_BUILD_DYNAMIC=true - if passed build dynamic binary without CGO
	@##~ GO_ENABLE_CGO=true - if passed build binary with CGO

go/build/mac/all: build/mac/all ## Build go app for all arch
	@##~ PROJECT_NAME=NAME - name of project. Required
	@##~ GO_TARGET=PKG_OR_FILE - path to package or go file to build. Required
	@##~ GO_BUILD_TAGS=TAGS... - comma-separated build tags. Optional
	@##~ GO_BUILD_VARIABLES=VARIABLES... - //||-separated variables to add to binary. Optional
	@##~ GO_BUILD_DYNAMIC=true - if passed build dynamic binary without CGO
	@##~ GO_ENABLE_CGO=true - if passed build binary with CGO

go/build/all: build/all ## Build go app for mac and linux for all arch
	@##~ PROJECT_NAME=NAME - name of project. Required
	@##~ GO_TARGET=PKG_OR_FILE - path to package or go file to build. Required
	@##~ GO_BUILD_TAGS=TAGS... - comma-separated build tags. Optional
	@##~ GO_BUILD_VARIABLES=VARIABLES... - //||-separated variables to add to binary. Optional
	@##~ GO_BUILD_DYNAMIC=true - if passed build dynamic binary without CGO
	@##~ GO_ENABLE_CGO=true - if passed build binary with CGO


##@ Go. Cleanup

clean/go: clean/build ## Remove gofumpt and olangci-lint binaries and tmp test dir and binaries produced by build
	@##~ REMOVE_COMMON=true - remove binaries for https://github.com/makefile-inc/common.git
	@##~   uses jq from https://github.com/makefile-inc/common.git
	@##~   By default: no remove
	@if [ -n "$$REMOVE_COMMON" ]; then $(MAKE) clean/common; fi; 
	@rm -fv "$(GOLANGCI_BIN_FULL)"
	@rm -fv "$(GOFUMPT_BIN_FULL)"
	@rm -rfv "$(GO_TESTS_TMP_DIR)"

.PHONY: check/installed/go install/go/gofumpt install/go/golangci-lint go/lint go/lint/fix go/tidy go/check/no-tidy go/test go/test/race go/test/force clean/go go/build/current go/build/linux go/build/mac/all go/build/mac go/build/all _go/build/target go/check/gitignore/itself
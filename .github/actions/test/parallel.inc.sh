#!/usr/bin/env bash

## Copied from https://gist.github.com/name212/713d715b94a627c2ef41c0425c4ae05b

## Functions to run commands or bash functions sequentially or parallel
## Functions uses associative array. Needs bash >= 4.2
## Full example:
## Save this content to ./parallel.inc.sh
##
# #!/usr/bin/env bash
#
# set -Eeuo pipefail
#
# # Declare global associative array with names of commands
# declare -A _tasks_to_msg
# _tasks_to_msg["aaa"]="Run gitignore"
# _tasks_to_msg["bbb"]="Run lint"
#
# # Source help functions
# source ./parallel.inc.sh
#
# # Declare functions
# function aaa() {
#     echo "Start aaa"
#     sleep 5
#     echo "End aaa"
#     return 0
# }
#
# function bbb() {
#     echo "Start and end bbb"
#     return 1
# }
#
# # For run in parallel export variable or pass over envs
# export RUN_IN_PARALLEL=true
#
# # Call util function 
# _run_tasks_and_exit "aaa" "bbb"
##

# Get task name from global associative array _tasks_to_msg
#   if declared. If not declared output passed task name
#   Function safe for run with:
#     set -Eeuo pipefail
# Arguments:
#   $1 - task name
function _task_name() {
    local task="${1:-}"
    local t_name="$task"
    if declare -p _tasks_to_msg &>/dev/null; then
        if [[ -v _tasks_to_msg["$task"] ]]; then
            t_name="${_tasks_to_msg["$task"]}"
        fi
    fi

    echo -n "$t_name"
}

# Run passed tasks functions or commands sequentially
#   Output (with stderr) of commands will directly out to terminal.
#   If at least one command failed - output list failed tasks in red color  
#   with exit code of command and return 1 exit code
#   If all tasks done without errors returns 0.
#   You can declare global associative array _tasks_to_msg (task_name -> pretty task name str)
#   to output pretty print task name.
#   If has internal error returns 255 code.
#   Function safe for run with: 
#     set -Eeuo pipefail
# Arguments: list of strings to run commands like:
#   _run_seq "function_name" "make test"
function _run_seq() {
    if [ "$#" -eq 0 ]; then
        echo -e "\033[0;31mTasks for _run_seq not passed\033[0m"
        return 255
    fi

    local -A failed=()
    for s_ts in "$@"; do
        if $s_ts; then
            true
        else
            failed["$s_ts"]="$?"
        fi
    done

    if [ "${#failed[@]}" -eq 0 ]; then
        return 0
    fi

    for s_ts in "${!failed[@]}"; do
        # shellcheck disable=SC2155
        local t_name="$(_task_name "$s_ts")"
        echo -e "\033[0;31m'$t_name' failed with exit code ${failed[$s_ts]}!\033[0m"
    done
    
    return 1 
}

# Run passed tasks functions or commands parallel
#   First command output (with stderr) will directly out to terminal
#   Another commands outputs will save to temp file (created by mktemp you can pass temp dir via env TMPDIR)
#   with prefix _run_parallel.
#   _run_parallel waits until all commands done. 
#   After wait, output non-first commands outputs from temp files in random order. 
#   Output for task will started with:
#     --- Output for TASK_NAME ---
#   and end with:
#     --- End output for TASK_NAME ---
#   Strings above will output with green color.
#   After output temp file will removed, but remove error will skipped.
#   If at least one command failed - output list failed tasks in red color  
#   and return 1 exit code.
#   If all tasks done without errors returns 0
#   You can declare global associative array _tasks_to_msg (task_name -> pretty task name str)
#   to output pretty print task name
#   If has internal error returns 255 code.
#   Function safe for run with: 
#     set -Eeuo pipefail
# Arguments: list of strings to run commands like:
#   _run_parallel "function_name" "make test"
function _run_parallel() {
    if [ "$#" -eq 0 ]; then
        echo -e "\033[0;31mTasks for _run_parallel not passed\033[0m"
        return 255
    fi

    local direct_output_task="$1"
    shift

    local -A task_to_out=()

    for p_ts in "$@"; do
        local tmp_file=""
        if ! tmp_file="$(mktemp "_run_parallel.XXXXXXXXXX")"; then
            # shellcheck disable=SC2155
            local t_name="$(_task_name "$p_ts")"
            echo -e "\033[0;31mCannot create tmp file for task ${t_name}\033[0m"
            return 255
        fi
        task_to_out["$p_ts"]="$tmp_file"
    done

    local -A task_to_pid=()

    $direct_output_task &
    task_to_pid["$direct_output_task"]="$!"

    for p_ts in "${!task_to_out[@]}"; do
        $p_ts &> "${task_to_out[$p_ts]}" &
        task_to_pid["$p_ts"]="$!"
    done
    
    local -A failed=()   

    for p_ts in "${!task_to_pid[@]}"; do
        if wait "${task_to_pid[$p_ts]}"; then
            true
        else
            failed["$p_ts"]="$?"
        fi
    done

    for out_ts in "${!task_to_out[@]}"; do
        local out_file="${task_to_out[$out_ts]}"
        echo -e "\033[0;32m--- Output for $out_ts ---\033[0m"
        cat "$out_file" || true
        echo -e "\033[0;32m--- End output for $out_ts ---\033[0m"
        rm -f "$out_file" || true
    done

    if [ "${#failed[@]}" -eq 0 ]; then
        return 0
    fi

    for p_ts in "${!failed[@]}"; do
        # shellcheck disable=SC2155
        local t_name="$(_task_name "$p_ts")"
        echo -e "\033[0;31m'$t_name' failed with exit code ${failed[$p_ts]}!\033[0m"
    done
    
    return 1
}

# Run passed tasks functions or commands parallel or sequentially
#   If passed env RUN_IN_PARALLEL=true - run tasks with _run_parallel
#   Otherwise run with _run_seq
#   Declare associative array _tasks_to_msg allowed here. 
#   Returns 0 code if run tasks done without error,
#   otherwise returns exit code from _run_parallel or _run_seq
#   Function safe for run with: 
#     set -Eeuo pipefail
# Arguments: list of strings to run commands like:
#   _run_tasks "function_name" "make test"
function _run_tasks() {
    local run_in_parallel="${RUN_IN_PARALLEL:-}"
    if [[ "$run_in_parallel" == "true" ]]; then
        if _run_parallel "$@"; then
            return 0
        else 
            return $?
        fi
    fi

    if _run_seq "$@"; then
        return 0
    else
        return $?
    fi
}

# Run passed tasks functions or commands parallel or sequentially 
#   with _run_tasks and exit script
#   RUN_IN_PARALLEL variable allowed for this function
#   Declare associative array _tasks_to_msg allowed here.
#   exit code get from _run_tasks function
#   Function safe for run with: 
#     set -Eeuo pipefail
# Arguments: list of strings to run commands like:
#   _run_tasks_and_exit "function_name" "make test"
function _run_tasks_and_exit() {
    if _run_tasks "$@"; then
        exit 0
    else
        exit $?
    fi
}

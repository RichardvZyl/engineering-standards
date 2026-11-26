#!/bin/sh
# POSIX tests: WSL translation, unset base, root leaf, primary checkout, no-branch, log mode.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
SCRIPT="$ROOT/.githooks/branch-location-guard.sh"
fail=0

assert_exit() {
    want=$1
    shift
    set +e
    out=$(env "$@" sh "$SCRIPT" 2>&1)
    code=$?
    set -e
    if [ "$code" -ne "$want" ]; then
        printf 'FAIL: expected exit %s got %s\n  cmd: %s\n  out: %s\n' "$want" "$code" "$*" "$out" >&2
        fail=$((fail + 1))
    else
        printf 'ok: exit %s\n' "$want"
    fi
}

assert_exit 1 \
    BRANCH_GUARD_BASE= \
    BRANCH_GUARD_TOPLEVEL=/mnt/e/Development/repositories/Owner/demo/feature \
    BRANCH_GUARD_MODE=enforce \
    BRANCH_GUARD_GIT_DIR=/tmp/wt/.git \
    BRANCH_GUARD_COMMON_DIR=/tmp/main/.git

assert_exit 0 \
    BRANCH_GUARD_BASE='E:\Development\repositories\Owner' \
    BRANCH_GUARD_TOPLEVEL=/mnt/e/Development/repositories/Owner/demo/feature \
    BRANCH_GUARD_MODE=enforce \
    BRANCH_GUARD_GIT_DIR=/mnt/e/Development/repositories/Owner/demo/root/.git/worktrees/feature \
    BRANCH_GUARD_COMMON_DIR=/mnt/e/Development/repositories/Owner/demo/root/.git

assert_exit 1 \
    BRANCH_GUARD_BASE='E:\Development\repositories\Owner' \
    BRANCH_GUARD_TOPLEVEL=/mnt/e/Development/repositories/Owner/demo/root \
    BRANCH_GUARD_MODE=enforce \
    BRANCH_GUARD_GIT_DIR=/mnt/e/x/.git/worktrees/x \
    BRANCH_GUARD_COMMON_DIR=/mnt/e/x/.git

assert_exit 1 \
    BRANCH_GUARD_BASE='E:\Development\repositories\Owner' \
    BRANCH_GUARD_TOPLEVEL=/mnt/e/Development/repositories/Owner/demo/feature \
    BRANCH_GUARD_MODE=enforce \
    BRANCH_GUARD_GIT_DIR=/mnt/e/Development/repositories/Owner/demo/feature/.git \
    BRANCH_GUARD_COMMON_DIR=/mnt/e/Development/repositories/Owner/demo/feature/.git

assert_exit 0 \
    BRANCH_GUARD_BASE='E:\Development\repositories\Owner' \
    BRANCH_GUARD_TOPLEVEL=/mnt/e/Development/repositories/Owner/demo/root \
    BRANCH_GUARD_MODE=log \
    BRANCH_GUARD_GIT_DIR=/mnt/e/x/.git/worktrees/x \
    BRANCH_GUARD_COMMON_DIR=/mnt/e/x/.git

assert_exit 0 \
    BRANCH_GUARD_MODE=no-branch \
    BRANCH_GUARD_BRANCH=main \
    BRANCH_GUARD_DEFAULT_BRANCH=main

assert_exit 1 \
    BRANCH_GUARD_MODE=no-branch \
    BRANCH_GUARD_BRANCH=feature \
    BRANCH_GUARD_DEFAULT_BRANCH=main

if [ "$fail" -ne 0 ]; then
    printf '%s test(s) failed\n' "$fail" >&2
    exit 1
fi
printf 'all posix path tests passed\n'
exit 0

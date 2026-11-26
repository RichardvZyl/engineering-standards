#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
SCRIPT="$ROOT/.githooks/branch-location-guard.sh"
fail=0

assert_exit() {
    want=$1; shift
    set +e
    out=$(env "$@" sh "$SCRIPT" 2>&1)
    code=$?
    set -e
    if [ "$code" -ne "$want" ]; then
        printf 'FAIL: expected %s got %s\n  %s\n  %s\n' "$want" "$code" "$*" "$out" >&2
        fail=$((fail + 1))
    else
        printf 'ok: exit %s\n' "$want"
    fi
}

assert_exit 1 BRANCH_GUARD_BASE= BRANCH_GUARD_TOPLEVEL=/mnt/e/dev/Owner/repo/feat \
    BRANCH_GUARD_MODE=enforce BRANCH_GUARD_GIT_DIR=/tmp/a BRANCH_GUARD_COMMON_DIR=/tmp/b

assert_exit 0 BRANCH_GUARD_BASE='E:\dev\Owner' \
    BRANCH_GUARD_TOPLEVEL=/mnt/e/dev/Owner/repo/feat \
    BRANCH_GUARD_MODE=enforce \
    BRANCH_GUARD_GIT_DIR=/mnt/e/dev/Owner/repo/root/.git/worktrees/feat \
    BRANCH_GUARD_COMMON_DIR=/mnt/e/dev/Owner/repo/root/.git

assert_exit 1 BRANCH_GUARD_BASE='E:\dev\Owner' \
    BRANCH_GUARD_TOPLEVEL=/mnt/e/dev/Owner/repo/root \
    BRANCH_GUARD_MODE=enforce \
    BRANCH_GUARD_GIT_DIR=/mnt/e/x/.git/worktrees/x \
    BRANCH_GUARD_COMMON_DIR=/mnt/e/x/.git

assert_exit 1 BRANCH_GUARD_BASE='E:\dev\Owner' \
    BRANCH_GUARD_TOPLEVEL=/mnt/e/dev/Owner/repo/feat \
    BRANCH_GUARD_MODE=enforce \
    BRANCH_GUARD_GIT_DIR=/mnt/e/dev/Owner/repo/feat/.git \
    BRANCH_GUARD_COMMON_DIR=/mnt/e/dev/Owner/repo/feat/.git

assert_exit 0 BRANCH_GUARD_BASE='E:\dev\Owner' \
    BRANCH_GUARD_TOPLEVEL=/mnt/e/dev/Owner/repo/root \
    BRANCH_GUARD_MODE=log \
    BRANCH_GUARD_GIT_DIR=/mnt/e/x/.git/worktrees/x \
    BRANCH_GUARD_COMMON_DIR=/mnt/e/x/.git

assert_exit 0 BRANCH_GUARD_MODE=no-branch BRANCH_GUARD_BRANCH=main BRANCH_GUARD_DEFAULT_BRANCH=main
assert_exit 1 BRANCH_GUARD_MODE=no-branch BRANCH_GUARD_BRANCH=feature BRANCH_GUARD_DEFAULT_BRANCH=main

[ "$fail" -eq 0 ] || { printf '%s failed\n' "$fail" >&2; exit 1; }
printf 'all posix path tests passed\n'

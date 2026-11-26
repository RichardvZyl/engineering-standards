#!/bin/sh
# Small POSIX test for branch-location-guard.sh path translation and decisions.
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
        printf 'ok: exit %s (%s)\n' "$want" "$*"
    fi
}

# Unset base -> refuse
assert_exit 1 \
    BRANCH_GUARD_BASE= \
    BRANCH_GUARD_TOPLEVEL=/mnt/e/Development/repositories/Owner/demo/feature \
    BRANCH_GUARD_MODE=location

# Worktree under base (WSL path vs Windows base) -> allow
assert_exit 0 \
    BRANCH_GUARD_BASE='E:\Development\repositories\Owner' \
    BRANCH_GUARD_TOPLEVEL=/mnt/e/Development/repositories/Owner/demo/feature \
    BRANCH_GUARD_MODE=location

# root leaf -> refuse
assert_exit 1 \
    BRANCH_GUARD_BASE='E:\Development\repositories\Owner' \
    BRANCH_GUARD_TOPLEVEL=/mnt/e/Development/repositories/Owner/demo/root \
    BRANCH_GUARD_MODE=location

# outside base -> refuse
assert_exit 1 \
    BRANCH_GUARD_BASE='E:\Development\repositories\Owner' \
    BRANCH_GUARD_TOPLEVEL=/mnt/d/elsewhere/demo/feature \
    BRANCH_GUARD_MODE=location

# no-branch allow
assert_exit 0 \
    BRANCH_GUARD_MODE=no-branch \
    BRANCH_GUARD_BRANCH=main \
    BRANCH_GUARD_DEFAULT_BRANCH=main

# no-branch refuse
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

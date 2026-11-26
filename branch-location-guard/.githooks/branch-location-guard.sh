#!/bin/sh
# POSIX decision helper for branch-location guard (WSL / no-pwsh fallback).
# Exit 0 = allow, 1 = refuse. Messages on stderr.
#
# Env:
#   BRANCH_GUARD_BASE   required in location mode
#   BRANCH_GUARD_MODE   "location" (default) or "no-branch"
# Overrides for tests:
#   BRANCH_GUARD_TOPLEVEL, BRANCH_GUARD_BRANCH, BRANCH_GUARD_DEFAULT_BRANCH
set -eu

die() {
    printf 'branch-location-guard: REFUSED. %s\n' "$*" >&2
    exit 1
}

is_wsl() {
    if [ -n "${WSL_DISTRO_NAME:-}" ]; then return 0; fi
    if [ -f /proc/version ] && grep -qi microsoft /proc/version 2>/dev/null; then return 0; fi
    return 1
}

# Convert a path to a comparable Windows-style lowercase form: x:\a\b
to_comparable() {
    p=$1
    # Trim trailing slashes
    p=$(printf '%s' "$p" | sed 's#[\\/]*$##')

    # /mnt/<letter>/... -> <letter>:\...
    case $p in
        /mnt/[A-Za-z]|/mnt/[A-Za-z]/*)
            letter=$(printf '%s' "$p" | sed -n 's#^/mnt/\([A-Za-z]\).*#\1#p' | tr '[:lower:]' '[:upper:]')
            rest=$(printf '%s' "$p" | sed 's#^/mnt/[A-Za-z]##; s#^/##; s#/#\\#g')
            if [ -n "$rest" ]; then
                p="${letter}:\\${rest}"
            else
                p="${letter}:"
            fi
            ;;
        [A-Za-z]:*|[A-Za-z]:\\*)
            p=$(printf '%s' "$p" | sed 's#/#\\#g')
            ;;
        *)
            if is_wsl && command -v wslpath >/dev/null 2>&1; then
                w=$(wslpath -w "$p" 2>/dev/null || true)
                if [ -n "$w" ]; then
                    p=$(printf '%s' "$w" | sed 's#/#\\#g; s#[\\/]*$##')
                fi
            fi
            ;;
    esac

    printf '%s' "$p" | tr '[:upper:]' '[:lower:]' | sed 's#[\\/]*$##'
}

resolve_mode() {
    mode=${BRANCH_GUARD_MODE:-}
    if [ -z "$mode" ] && command -v git >/dev/null 2>&1; then
        mode=$(git config --get branchGuard.mode 2>/dev/null || true)
    fi
    mode=$(printf '%s' "$mode" | tr '[:upper:]' '[:lower:]')
    case $mode in
        no-branch|nobranch) printf 'no-branch' ;;
        *) printf 'location' ;;
    esac
}

default_branch() {
    if [ -n "${BRANCH_GUARD_DEFAULT_BRANCH:-}" ]; then
        printf '%s' "$BRANCH_GUARD_DEFAULT_BRANCH"
        return
    fi
    sym=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || true)
    case $sym in
        refs/remotes/origin/*) printf '%s' "${sym#refs/remotes/origin/}"; return ;;
    esac
    for c in main master; do
        if git show-ref --verify --quiet "refs/remotes/origin/$c" 2>/dev/null \
            || git show-ref --verify --quiet "refs/heads/$c" 2>/dev/null; then
            printf '%s' "$c"
            return
        fi
    done
    printf 'main'
}

current_branch() {
    if [ -n "${BRANCH_GUARD_BRANCH:-}" ]; then
        printf '%s' "$BRANCH_GUARD_BRANCH"
        return
    fi
    git branch --show-current 2>/dev/null || true
}

toplevel() {
    if [ -n "${BRANCH_GUARD_TOPLEVEL:-}" ]; then
        printf '%s' "$BRANCH_GUARD_TOPLEVEL"
        return
    fi
    git rev-parse --show-toplevel 2>/dev/null || die "not inside a git work tree"
}

mode=$(resolve_mode)

if [ "$mode" = "no-branch" ]; then
    cur=$(current_branch)
    def=$(default_branch)
    [ -n "$cur" ] || die "no-branch mode refuses detached HEAD; check out the default branch"
    [ "$cur" = "$def" ] || die "no-branch mode: current branch '$cur' is not the default branch '$def'. Do not create or commit on other branches in this repository."
    exit 0
fi

base=${BRANCH_GUARD_BASE:-}
[ -n "$base" ] || die "BRANCH_GUARD_BASE is not set. Set it to the repositories owner folder (the directory that contains each <repo>/root and <repo>/<worktree> pair), then retry. There is no hardcoded default."

top=$(toplevel)
cmp_base=$(to_comparable "$base")
cmp_top=$(to_comparable "$top")

case $cmp_top in
    "$cmp_base"|"$cmp_base"\\*) ;;
    *) die "toplevel '$top' is outside BRANCH_GUARD_BASE. Clones and worktrees must live under the configured base." ;;
esac

# Relative segments under base
rel=
if [ "$cmp_top" = "$cmp_base" ]; then
    rel=
else
    prefix="$cmp_base\\"
    rel=${cmp_top#"$prefix"}
fi

# Count segments
n=0
repo=
leaf=
old_ifs=$IFS
IFS='\'
# shellcheck disable=SC2086
set -- $rel
IFS=$old_ifs
n=$#
if [ "$n" -ge 1 ]; then repo=$1; fi
if [ "$n" -ge 2 ]; then leaf=$2; fi

[ "$n" -eq 2 ] || die "toplevel must be BRANCH_GUARD_BASE/<repo>/<worktree> (exactly two levels under the base). Got $n level(s) under the base. Never commit from the repository folder itself or from nested paths."

leaf_lc=$(printf '%s' "$leaf" | tr '[:upper:]' '[:lower:]')
[ "$leaf_lc" != "root" ] || die "commits and pushes are not allowed from <repo>/root. Create a linked worktree beside root and work there."

# unused but keeps shellcheck happy about repo
: "$repo"

exit 0

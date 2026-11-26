#!/bin/sh
# POSIX decision helper for branch-location-guard (WSL / no-pwsh fallback).
# Mirrors Get-Decision: OutsideBase, WrongDepth, RootLeaf, PrimaryCheckout.
# Exit 0 = allow (or log-mode soft allow), 1 = refuse.
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

to_comparable() {
    p=$1
    p=$(printf '%s' "$p" | sed 's#[\\/]*$##')

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

write_log() {
    leaf=$1
    decision=$2
    log=${BRANCH_GUARD_LOG:-}
    [ -n "$log" ] || return 0
    [ -n "$leaf" ] || leaf='-'
    dir=$(dirname "$log")
    if [ -n "$dir" ] && [ "$dir" != '.' ]; then
        mkdir -p "$dir" 2>/dev/null || true
    fi
    printf '%s %s\n' "$leaf" "$decision" >>"$log"
}

resolve_mode() {
    mode=${BRANCH_GUARD_MODE:-}
    if [ -z "$mode" ] && command -v git >/dev/null 2>&1; then
        mode=$(git config --get branchGuard.mode 2>/dev/null || true)
    fi
    mode=$(printf '%s' "$mode" | tr '[:upper:]' '[:lower:]')
    case $mode in
        log) printf 'log' ;;
        no-branch|nobranch) printf 'no-branch' ;;
        location|enforce|'') printf 'enforce' ;;
        *) printf 'enforce' ;;
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

refuse() {
    code=$1
    leaf=$2
    shift 2
    write_log "$leaf" "$code"
    if [ "$(resolve_mode)" = "log" ]; then
        printf 'branch-location-guard: LOG %s — %s\n' "$code" "$*" >&2
        exit 0
    fi
    die "$*"
}

mode=$(resolve_mode)

if [ "$mode" = "no-branch" ]; then
    cur=$(current_branch)
    def=$(default_branch)
    [ -n "$cur" ] || refuse NoBranchDetached '' "no-branch mode refuses detached HEAD; check out the default branch"
    if [ "$cur" != "$def" ]; then
        refuse NoBranchWrongBranch "$cur" "no-branch mode: current branch '$cur' is not the default branch '$def'. Do not create or commit on other branches in this repository."
    fi
    write_log "$cur" Allow
    exit 0
fi

base=${BRANCH_GUARD_BASE:-}
[ -n "$base" ] || refuse UnsetBase '' "BRANCH_GUARD_BASE is not set. Set it to the repositories owner folder (the directory that contains each <repo>/root and <repo>/<worktree> pair), then retry. There is no hardcoded default."

root_name=${BRANCH_GUARD_ROOT_NAME:-root}
root_lc=$(printf '%s' "$root_name" | tr '[:upper:]' '[:lower:]')

top=$(toplevel)
cmp_base=$(to_comparable "$base")
cmp_top=$(to_comparable "$top")

case $cmp_top in
    "$cmp_base"|"$cmp_base"\\*) ;;
    *) refuse OutsideBase '' "toplevel '$top' is outside BRANCH_GUARD_BASE. Clones and worktrees must live under the configured base." ;;
esac

rel=
if [ "$cmp_top" = "$cmp_base" ]; then
    rel=
else
    prefix="$cmp_base\\"
    rel=${cmp_top#"$prefix"}
fi

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

[ "$n" -eq 2 ] || refuse WrongDepth "$leaf" "toplevel must be BRANCH_GUARD_BASE/<repo>/<worktree> (exactly two levels under the base). Got $n level(s) under the base. Never commit from the repository folder itself or from nested paths."

leaf_lc=$(printf '%s' "$leaf" | tr '[:upper:]' '[:lower:]')
[ "$leaf_lc" != "$root_lc" ] || refuse RootLeaf "$leaf" "commits and pushes are not allowed from <repo>/$root_name. Create a linked worktree beside $root_name and work there."

# Primary checkout check: git-dir == common-dir
if [ -n "${BRANCH_GUARD_GIT_DIR:-}" ] && [ -n "${BRANCH_GUARD_COMMON_DIR:-}" ]; then
    gd=$BRANCH_GUARD_GIT_DIR
    cdn=$BRANCH_GUARD_COMMON_DIR
else
    gd=$(git rev-parse --path-format=absolute --git-dir 2>/dev/null || true)
    cdn=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)
fi
if [ -n "$gd" ] && [ -n "$cdn" ]; then
    cmp_gd=$(to_comparable "$gd")
    cmp_cdn=$(to_comparable "$cdn")
    if [ "$cmp_gd" = "$cmp_cdn" ]; then
        refuse PrimaryCheckout "$leaf" "git-dir equals git-common-dir — this is the primary checkout, not a linked worktree. Work only in a linked worktree under BRANCH_GUARD_BASE/<repo>/<worktree>."
    fi
fi

: "$repo"
write_log "$leaf" Allow
exit 0

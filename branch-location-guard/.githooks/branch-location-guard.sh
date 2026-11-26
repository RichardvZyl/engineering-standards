#!/bin/sh
# POSIX fallback mirroring Get-Decision (original reasons) + approved WSL/no-branch.
set -eu

die() {
    printf 'BRANCH LOCATION GUARD: manual refused (%s). Create a worktree next to root\\ and work there: <base>\\<repo>\\<new-worktree>. See AGENTS.md.\n' "$*" >&2
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
            if [ -n "$rest" ]; then p="${letter}:\\${rest}"; else p="${letter}:"; fi
            ;;
        [A-Za-z]:*|[A-Za-z]:\\*) p=$(printf '%s' "$p" | sed 's#/#\\#g') ;;
        *)
            if is_wsl && command -v wslpath >/dev/null 2>&1; then
                w=$(wslpath -w "$p" 2>/dev/null || true)
                if [ -n "$w" ]; then p=$(printf '%s' "$w" | sed 's#/#\\#g; s#[\\/]*$##'); fi
            fi
            ;;
    esac
    printf '%s' "$p" | tr '[:upper:]' '[:lower:]' | sed 's#[\\/]*$##'
}

write_log() {
    msg=$1
    log=${BRANCH_GUARD_LOG:-}
    [ -n "$log" ] || return 0
    ts=$(date -Iseconds 2>/dev/null || date)
    printf '%s %s\n' "$ts" "$msg" >>"$log" 2>/dev/null || true
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
        *) printf 'enforce' ;;
    esac
}

refuse() {
    reason=$1
    repo=$2
    mode=$(resolve_mode)
    write_log "manual repo=${repo} allowed=False mode=${mode} reason=${reason}"
    if [ "$mode" = "log" ]; then
        printf 'BRANCH LOCATION GUARD: manual refused (%s). Create a worktree next to root\\ and work there: <base>\\<repo>\\<new-worktree>. See AGENTS.md.\n' "$reason" >&2
        exit 0
    fi
    die "$reason"
}

mode=$(resolve_mode)

if [ "$mode" = "no-branch" ]; then
    cur=${BRANCH_GUARD_BRANCH:-}
    if [ -z "$cur" ]; then cur=$(git branch --show-current 2>/dev/null || true); fi
    def=${BRANCH_GUARD_DEFAULT_BRANCH:-}
    if [ -z "$def" ]; then
        sym=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || true)
        case $sym in refs/remotes/origin/*) def=${sym#refs/remotes/origin/} ;; esac
    fi
    [ -n "$def" ] || def=main
    [ -n "$cur" ] || refuse "undecidable: detached HEAD" "?"
    [ "$cur" = "$def" ] || refuse "no-branch mode: current branch '$cur' is not the default branch '$def'" "$cur"
    write_log "manual repo=${cur} allowed=True mode=no-branch reason=ok"
    exit 0
fi

base=${BRANCH_GUARD_BASE:-}
[ -n "$base" ] || refuse "undecidable: BRANCH_GUARD_BASE is not set" "?"

root_name=${BRANCH_GUARD_ROOT_NAME:-root}
root_lc=$(printf '%s' "$root_name" | tr '[:upper:]' '[:lower:]')

if [ -n "${BRANCH_GUARD_TOPLEVEL:-}" ]; then top=$BRANCH_GUARD_TOPLEVEL
else top=$(git rev-parse --show-toplevel 2>/dev/null) || refuse "undecidable: git returned an empty path" "?"
fi

cmp_base=$(to_comparable "$base")
cmp_top=$(to_comparable "$top")

case $cmp_top in
    "$cmp_base"\\*) ;;
    *)
        leaf=$(printf '%s' "$cmp_top" | sed 's#.*\\##')
        refuse "outside-base" "$leaf"
        ;;
esac

# parent = Split-Path top; repoDir = Split-Path parent; repoName = leaf of parent
parent=$(printf '%s' "$cmp_top" | sed 's#\\[^\\]*$##')
repo_dir=$(printf '%s' "$parent" | sed 's#\\[^\\]*$##')
repo_name=$(printf '%s' "$parent" | sed 's#.*\\##')
leaf=$(printf '%s' "$cmp_top" | sed 's#.*\\##')

cmp_repo_dir=$(to_comparable "$repo_dir")
[ "$cmp_repo_dir" = "$cmp_base" ] || refuse "wrong-depth (expected <base>\\<repo>\\<worktree>)" "$repo_name"

leaf_lc=$(printf '%s' "$leaf" | tr '[:upper:]' '[:lower:]')
[ "$leaf_lc" != "$root_lc" ] || refuse "branching inside ${root_name}\\ is not allowed" "$repo_name"

if [ -n "${BRANCH_GUARD_GIT_DIR:-}" ] && [ -n "${BRANCH_GUARD_COMMON_DIR:-}" ]; then
    gd=$BRANCH_GUARD_GIT_DIR; cdn=$BRANCH_GUARD_COMMON_DIR
else
    gd=$(git rev-parse --path-format=absolute --git-dir 2>/dev/null || true)
    cdn=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)
fi
if [ -n "$gd" ] && [ -n "$cdn" ]; then
    cmp_gd=$(to_comparable "$gd")
    cmp_cdn=$(to_comparable "$cdn")
    if [ "$cmp_gd" = "$cmp_cdn" ]; then
        refuse "not a linked worktree (git-dir equals common-dir)" "$repo_name"
    fi
fi

write_log "manual repo=${repo_name} allowed=True mode=${mode} reason=ok"
exit 0

> Source: E:\Development\repositories\RichardvZyl\engineering-standards\no-code-without-repo-20261106\.perseus\context.md | Branch: standards/no-code-without-repo-20261106 | Commit: 204ebdb 2026-09-05 | Status: committed on standards/no-code-without-repo-20261106 | Copied: 2026-11-06 07:57 SAST (working copy - edit the source, not this file)

@perseus

@prompt
This document was rendered by Perseus for the Generic markdown profile. The resolved
content below reflects the workspace at render time. Avoid re-discovering the
same facts, but verify anything stale, surprising, or load-bearing with live
tools before relying on it — rendered context is a snapshot, not ground truth.
@end

# Workspace Context — @date format="YYYY-MM-DD HH:mm z"

**Profile:** generic

---

## Last Checkpoint
@waypoint ttl=86400

---

## Workspace State

@query "git log --oneline -5 2>/dev/null || echo '(no git repo)'" fallback="git log unavailable"
@query "git status --short 2>/dev/null || true" fallback="clean"

---

## Task Board
@agora status=open,in_progress

---

## Project Memory
@memory focus=recent ttl=300

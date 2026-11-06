@perseus

@prompt
This document was rendered by Perseus for the Generic markdown profile. The resolved
content below reflects the workspace at render time. Avoid re-discovering the
same facts, but verify anything stale, surprising, or load-bearing with live
tools before relying on it — rendered context is a snapshot, not ground truth.
@end

# Workspace Context — @date format="YYYY-MM-DD HH:mm z"

**Profile:** generic

## Project
- **Purpose:** A worktree of `engineering-standards`, the upstream source of the engineering conventions. `standards/` is vendored into consuming repos, and a scheduled workflow opens a sync pull request when a vendored copy falls behind. This checkout carries a lockdown handoff for 2026-10-16.
- **Layout:**
  - `standards/` - the synced conventions set; read-only in consuming repos.
  - `templates/` - seeded once and then owned by the consuming repo: AGENTS.md template, ADR scaffolding, domain-doc and PR templates, optional AI-tooling notes under `templates/docs/ai/`.
  - `scripts/` - `Sync-Standards.ps1`, `Test-NoProprietaryLeak.ps1`, `Test-StandardsIntegrity.ps1`.
  - `.github/workflows/` - `standards-sync.yml` (the only workflow synced downstream) and `verify-standards.yml` (runs here).
  - `HANDOFF-2026-10-16-lockdown.md` and `handoff-2026-10-16/` - the lockdown handoff note and its supporting folder.
  - `.perseus/` - Perseus context source and `pack.yaml`; `live-context.md` is its generated render.
  - `CHANGELOG.md`, `README.md`, `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.editorconfig`, `LICENSE`.
- **Stack and build:** PowerShell scripts, GitHub Actions workflows and Markdown. The `verify-standards.yml` workflow runs the leak and integrity scripts. Exact local commands are not shown in the repo facts.
- **Conventions and constraints:**
  - AGENTS.md is the canonical agent entry; CLAUDE.md and .cursorrules point to it. It governs work on `engineering-standards` itself, not the file consuming repos receive.
  - The template carries the convention, never the instance. No repo, org, client or product names, no machine-local paths, and no real schemas under `standards/`.
  - Do not weaken `Test-NoProprietaryLeak.ps1` to pass a build; if it fires, fix the content. Tokens are added with `-AddToken`.
  - A change to `standards/**` needs a `standards/VERSION` bump and its own dated `CHANGELOG.md` block. Every standard keeps the read-only vendoring header.
  - Do not edit `live-context.md` by hand; edit `.perseus/context.md`.
- **Status:** Branch `handoff/lockdown-2026-10-16`. The latest commit adds the lockdown handoff (in-flight state, unpushed work, A2A findings), on top of standards 09-16 work (#15), optional AI-tooling notes (#11) and git discipline (v0.6.0, #12).

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

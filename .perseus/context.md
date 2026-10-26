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
- **Purpose:** A worktree of `engineering-standards` used to develop standards 09 through 16 (durable references, worktree layout, evidence, data boundaries, concurrent agents and working memory, and related items). `standards/` is vendored into consuming repos by a sync pull request.
- **Layout:**
  - `standards/` - the synced conventions set; read-only in consuming repos.
  - `templates/` - seeded once and then owned by the consuming repo.
  - `scripts/` - `Sync-Standards.ps1`, `Test-NoProprietaryLeak.ps1`, `Test-StandardsIntegrity.ps1`, and `deny-tokens.sha256` for the leak guard.
  - `.github/workflows/` - `standards-sync.yml` (synced downstream) and `verify-standards.yml` (runs here).
  - `.perseus/` - Perseus context source and `pack.yaml`; `live-context.md` is its generated render.
  - `CHANGELOG.md`, `README.md`, `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.editorconfig`, `LICENSE`.
- **Stack and build:** PowerShell scripts, GitHub Actions workflows and Markdown. The `verify-standards.yml` workflow runs the leak and integrity scripts. Exact local commands are not shown in the repo facts.
- **Conventions and constraints:**
  - AGENTS.md is the canonical agent entry; CLAUDE.md and .cursorrules point to it.
  - The template carries the convention, never the instance: no repo, org, client or product names and no machine-local paths in `standards/`.
  - Do not weaken `Test-NoProprietaryLeak.ps1` to pass a build; tokens are added with `-AddToken`.
  - A change to `standards/**` needs a `standards/VERSION` bump and its own dated `CHANGELOG.md` block; never fold a rule into an earlier version's block.
  - Do not edit `live-context.md` by hand; edit `.perseus/context.md`.
- **Status:** Branch `standards/09-through-15`. Recent commits add standard 16 (working memory), generalise the vendored protocol, scope the WAL backup procedure in standard 12, cut the dated 0.7.0 changelog block, and set the version at 0.7.0.

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

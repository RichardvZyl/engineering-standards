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
- **Purpose:** The base checkout (`root`) of `engineering-standards`, the upstream source of the engineering conventions. `standards/` is vendored into consuming repos and a sync pull request keeps each copy current.
- **Layout:**
  - `standards/` - the synced conventions set; read-only in consuming repos.
  - `templates/` - seeded once and then owned by the consuming repo (AGENTS.md template, ADR scaffolding, domain-doc and PR templates, optional notes under `templates/docs/ai/`).
  - `scripts/` - `Sync-Standards.ps1`, `Test-NoProprietaryLeak.ps1`, `Test-StandardsIntegrity.ps1`.
  - `.github/workflows/` - `standards-sync.yml` (synced downstream) and `verify-standards.yml` (runs here).
  - `.agents/reconcile.md` - agent working notes folder.
  - `.perseus/` - Perseus context source and `pack.yaml`; `live-context.md` is its generated render.
  - `CHANGELOG.md`, `README.md`, `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.editorconfig`, `LICENSE`.
- **Stack and build:** PowerShell scripts, GitHub Actions workflows and Markdown. The `verify-standards.yml` workflow runs the leak and integrity scripts. Exact local commands are not shown in the repo facts.
- **Conventions and constraints:**
  - AGENTS.md is the canonical agent entry; CLAUDE.md and .cursorrules point to it. It governs work on `engineering-standards` itself.
  - The template carries the convention, never the instance: no repo, org, client or product names and no machine-local paths in `standards/`.
  - Do not weaken `Test-NoProprietaryLeak.ps1` to pass a build; tokens are added with `-AddToken`.
  - A change to `standards/**` needs a `standards/VERSION` bump and its own dated `CHANGELOG.md` block. Every standard keeps the read-only vendoring header.
  - Do not edit `live-context.md` by hand; edit `.perseus/context.md`.
- **Status:** Branch `main`. Recent commits add optional APM, agentrc, AGT and Perseus/Vault notes (#11), git branch/stash/PR-sequencing standards (v0.6.0, #12), and fixes such as resolving perseus from PATH and correcting the .gitignore header.

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

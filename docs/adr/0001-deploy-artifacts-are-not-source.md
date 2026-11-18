# 0001 — Deploy artifacts are not source

- **Status:** Accepted
- **Date:** 2026-11-18
- **Cost to reverse:** Costly — every consuming service must re-teach agents that deploy
  trees are editable, drop refuse-to-start and read-only ACLs, and reintroduce raw-source
  publish; bounded and plannable, but not a single revert once publish pipelines have moved

## Context

On 2026-11-18 an agent edited TypeScript and policy in place under a deploy junction
(`…/current` → a content-addressed release folder) for a loopback Node service deployed as
a content-addressed release. That tree was **not a git repository**. It was a published
runtime snapshot. Canonical source belonged under `${dev-root}/repositories/<owner>/<repo>/`
on a `fully-merged` line. The launcher historically ran the TypeScript entry from the deploy
folder, so the publish accidentally looked like a project (full `.ts`, tests, editable
siblings). Rollback required a dated recovery copy outside the deploy root.

The estate already had settled conventions this decision must honour rather than reopen:

1. **Vendored standards header** — every `standards/*.md` carries the VENDORED — READ-ONLY
   banner.
2. **Numbered standard file** — `standards/NN-kebab-case-title.md` with a permanent number.
3. **Named section ids** — sections like `18.1` with bold **Rule.** /
   **Decided. Do not relitigate.** where settled (see standard 10.2).
4. **`${dev-root}` path form** — never absolute machine paths (standards 09, 14.0). Source
   under `${dev-root}/repositories`; a deploy/runtime root is a configured value.
5. **Convention vs instance** — standards never name repos/orgs/products/clients; those go
   in `AGENTS.md` (standard 07).
6. **ADR format** — this record's shape (standard 05), with index update in the same change.
7. **VERSION + CHANGELOG** — semver of the standards set; minor when a rule is added.
8. **README standards table** — new standard listed.
9. **Integrity scripts** — `Test-StandardsIntegrity.ps1` and `Test-NoProprietaryLeak.ps1`.
10. **Work from `fully-merged`, not dirty WIP or live deploy trees** (standard 10).

The forced decision: how a runnable service may be laid out and published so agents cannot
mistake output for source again.

## Options considered

| Option | Upside | Downside | Cost to reverse |
|---|---|---|---|
| Status quo — in-place `.ts` deploy (do nothing) | No publish work; launcher stays simple | Deploy tree looks like a repo; agents edit unversioned snapshots; next publish fights or overwrites silent drift | Reversible — none beyond leaving the hazard in place |
| Publish bundle *(chosen)* — content-addressed release, GENERATED banner + refuse-to-start, read-only code, config separated, `BUILD.json`, minify + mild obfuscation from `fully-merged` | Deploy no longer looks editable; provenance is queryable; in-place edits fail loudly | Publish script and ACLs to maintain; ops config must be split from code; agents need the new refusal signals | Costly — rework publish pipelines and drop guards across services |
| Run editable source directly from `${dev-root}/repositories` | Single tree; no publish step | Hosts repositories as mutable runtime; couples deploy to WIP worktrees; breaks the root/worktree recoverability model in standard 10 | Costly — re-separate runtime from every checkout once the coupling lands |

## Decision

Published deploy trees are **not repositories**. Services publish through a **single
publish-only path** that builds from `fully-merged` (or the designated fully-merged release
ref), minifies and applies mild deterministic obfuscation, writes a content-addressed
folder, flips `current`, stamps `BUILD.json`, and leaves code artifacts read-only with a
GENERATED banner the launcher enforces. Editable ops inputs stay outside the immutable
code bundle. Source edits happen only under `${dev-root}/repositories` on a proper
worktree. The conventions are recorded as standard
[`18`](../../standards/18-deploy-artifacts-are-not-source.md).

What settled it: the status-quo tree *looked* like a project and therefore *was* edited as
one; only making the published artifact unmistakably non-source (shape, banner, permissions,
and start refusal together) closes the failure mode.

## Consequences

- Every service that today ships raw TypeScript (or equivalent) as the runnable entrypoint
  needs a publish script and a one-time cutover to content-addressed releases.
- Launchers gain a hard dependency on the GENERATED banner and on the absence of sibling
  sources — a missing banner is an outage until republish, which is intentional.
- Ops policy and peer-state must not live as unmarked siblings of the entrypoint; splitting
  them is required work, not optional tidy-up.
- Health/status surfaces become part of provenance: if they cannot echo build identity,
  operators have no cheap way to confirm what is running.
- Agents are steered to `fully-merged` for anything that must run; dirty WIP trees and live
  deploy trees are not publish inputs.
- Unwelcome but accepted: mild obfuscation adds a small build step and makes emergency
  hotfixes *harder* — that friction is the point; the allowed path is rebuild and republish.

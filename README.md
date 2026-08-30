# engineering-standards

My engineering conventions, in one place, in a form a repo can actually consume.

Global agent conventions already distribute through symlinked skill directories. Per-repo
files — `.editorconfig`, `AGENTS.md`, `docs/adr/` — cannot be linked that way, so in practice
they get copied once and then quietly rot. This repo fixes that half: `standards/` is vendored
into each consuming repo and a scheduled workflow opens a **pull request** whenever the vendored
copy falls behind upstream.

Drift you can see in a PR is a decision. Drift you cannot see is just entropy.

> **Status: released at `v0.5.0`.** Every file described below exists. The sync script is tested
> end-to-end against a fixture upstream — added, changed and deleted files, idempotent re-run,
> `-WhatIf`, and a verified refusal to write outside `standards/` — but has not yet run against a
> live consuming repository, and no repository has consumed the standards set yet.

---

## What is here

| Path | Synced downstream? | Purpose |
|---|---|---|
| `standards/` | **Yes** — the synced set | The conventions themselves. Read-only in consuming repos. |
| `templates/` | No — seeded once | Starting points a repo edits and owns: `AGENTS.md`, ADR scaffolding, domain-doc template, PR template. |
| `scripts/` | No | `Sync-Standards.ps1` · `Test-NoProprietaryLeak.ps1` · `Test-StandardsIntegrity.ps1` |
| `.github/workflows/` | `standards-sync.yml` only | Sync opens the drift PR downstream; verify runs here. |

### The standards set

| File | Owns |
|---|---|
| `00-response-and-collaboration.md` | How an assistant should answer: density not brevity, where to go wide, what is never decided silently |
| `01-architecture-defaults.md` | Multi-tenancy, read/write separation, result types, idempotency for money, contention |
| `02-database-standards.md` | The database **rules** — exact types, tenant predicate, isolation, SARGability, indexing, scale, migrations |
| `03-engineering-hygiene.md` | Style by configuration, git, secrets, compliance, tests, dependencies |
| `04-documentation-layout.md` | Where docs live and which file owns what, and **planning item identifiers** |
| `05-decision-records.md` | ADR format; required by cost to reverse, not by importance |
| `06-review-standards.md` | The two review axes, kept deliberately unmerged |
| `07-repo-layout.md` | Directory shape, naming, and the conventions/context division |
| `08-keeping-documents-current.md` | What closing something obliges: the surfaces to sync, the stale-reference sweep, the debt marker |

### The scripts

| Script | Does |
|---|---|
| `Sync-Standards.ps1` | Mirrors `standards/` from upstream, deletions included. Verifies its target resolves inside the repository root and **refuses to run otherwise**. Never commits, pushes or merges — it changes files and reports; the workflow decides what to do with that. |
| `Test-NoProprietaryLeak.ps1` | Fails on a denied name, a credential pattern, a machine-local path, or a committed `*.private.md`. |
| `Test-StandardsIntegrity.ps1` | Vendoring header on every standard, valid semver, resolvable relative links, ADR index consistency. |

---

## Using it

**New repo** — generate from this template on GitHub, then delete what you do not need.
`templates/` is yours to edit from that moment; `standards/` is not.

**Existing repo** — copy `standards/` in and commit, then add
`.github/workflows/standards-sync.yml` too and the next scheduled run keeps it current. Without
that workflow, re-copy by hand when `standards/VERSION` changes.

Either way `standards/` is **read-only downstream**. Every file under it says so in its own
header, because a rule stated only in a README is a rule nobody reads. Disagree with a
standard? Change it here, upstream, and let the PR carry it everywhere.

### How the sync behaves

*The workflow exists and runs on its weekly cron. It has not yet run against a consuming
repository — every run so far has been in this repository, where there is nothing to sync.*

Weekly cron plus `workflow_dispatch`. It fetches this repo, diffs `standards/**` against the
local copy, and opens or updates a PR titled `Standards sync: <from> → <to>` using
`standards/VERSION`.

It **never auto-merges** and **never touches anything outside `standards/`**.

---

## The rule that governs every line here

**The template carries the convention, never the instance.**

If a line names a repo, org, client or product, it is project context and belongs in that
project's own `AGENTS.md` — not here. This repo is public precisely because conventions are
method, not material; the moment an instance leaks in, that stops being true.

This is enforced, not promised. `scripts/Test-NoProprietaryLeak.ps1` runs on every push and
fails the build on a denied name, a credential pattern, a machine-local path, or a committed
`*.private.md`. It stores its deny list as SHA-256 digests so that the guard does not itself
publish the names it exists to exclude.

---

## Composition — which document owns what

Three documents cover overlapping database ground. There is no third copy of the same content:

| Document | Owns | Shape |
|---|---|---|
| `standards/02-database-standards.md` | **The rule** — what must be true | "Money is `decimal`. Every query carries a tenant predicate." |
| `standards/reference/dotnet-sql-baseline.md` | **The review checklist** — how to spot a breach in a diff | "Lost update: a `SaveChanges` on an entity fetched earlier in the same method." |
| `AI-CONTEXT.md` §5 *(public CV repo)* | **The public summary** | Prose, for a reader not in the codebase |

Where `02` and the public summary disagree, **`02` wins** and the summary is updated to match.

---

## Licence

MIT — see [`LICENSE`](./LICENSE).
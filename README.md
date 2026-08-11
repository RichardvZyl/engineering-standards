# engineering-standards

My engineering conventions, in one place, in a form a repo can actually consume.

Global agent conventions already distribute through symlinked skill directories. Per-repo
files — `.editorconfig`, `AGENTS.md`, `docs/adr/` — cannot be linked that way, so in practice
they get copied once and then quietly rot. This repo fixes that half: `standards/` is vendored
into each consuming repo and a scheduled workflow opens a **pull request** whenever the vendored
copy falls behind upstream.

Drift you can see in a PR is a decision. Drift you cannot see is just entropy.

> **Status.** All eight standards and `templates/` are written (`standards/VERSION` 0.2.0). The
> **sync half is not built yet** — `scripts/Sync-Standards.ps1` and
> `.github/workflows/standards-sync.yml` are described below but do not exist, so nothing is
> currently kept current automatically. Copy `standards/` in by hand until they land. ✅ below
> marks what is present.

---

## What is here

| Path | Synced downstream? | Purpose | |
|---|---|---|---|
| `standards/` | **Yes** — the synced set | The conventions themselves. Read-only in consuming repos. | ✅ |
| `templates/` | No — seeded once | Starting points a repo edits and owns: `AGENTS.md`, ADR scaffolding, domain-doc template. | ✅ |
| `scripts/` | No | `Test-NoProprietaryLeak.ps1` ✅ · `Sync-Standards.ps1` **not built** | partial |
| `.github/workflows/` | `standards-sync.yml` only | Sync opens the drift PR downstream; verify runs here. | **not built** |

### The standards set

| File | Owns | |
|---|---|---|
| `00-response-and-collaboration.md` | How an assistant should answer: density not brevity, where to go wide | ✅ |
| `01-architecture-defaults.md` | Multi-tenancy, CQRS, result types, idempotency, contention | ✅ |
| `02-database-standards.md` | The database **rules** — money, SARGability, indexing, isolation, scale | ✅ |
| `03-engineering-hygiene.md` | Style, git, compliance, tests | ✅ |
| `04-documentation-layout.md` | Where docs live and which file owns what, and **planning item identifiers** | ✅ |
| `05-decision-records.md` | ADR format, when one is required | ✅ |
| `06-review-standards.md` | Review tiers and what each looks for | ✅ |
| `07-repo-layout.md` | Directory conventions | ✅ |

---

## Using it

**New repo** — generate from this template on GitHub, then delete what you do not need.
`templates/` is yours to edit from that moment; `standards/` is not.

**Existing repo** — copy `standards/` in and commit. Once the sync workflow exists, add
`.github/workflows/standards-sync.yml` too and the next scheduled run keeps it current; until
then, re-copy when `standards/VERSION` changes.

Either way `standards/` is **read-only downstream**. Every file under it says so in its own
header, because a rule stated only in a README is a rule nobody reads. Disagree with a
standard? Change it here, upstream, and let the PR carry it everywhere.

### How the sync will behave

*Not built yet — this is the intended design, not current behaviour.*

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
| `dotnet-sql-baseline.md` *(review kit)* | **The review checklist** — how to spot a breach in a diff | "Lost update: a `SaveChanges` on an entity fetched earlier in the same method." |
| `AI-CONTEXT.md` §5 *(public CV repo)* | **The public summary** | Prose, for a reader not in the codebase |

Where `02` and the public summary disagree, **`02` wins** and the summary is updated to match.

---

## Licence

MIT — see [`LICENSE`](./LICENSE).
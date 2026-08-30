# Changelog

Notable changes to this repository. Changes under `standards/` are what downstream repos
actually receive, so they are listed first in each release and carry the `standards/VERSION`
they ship with.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning is
[Semantic Versioning](https://semver.org/spec/v2.0.0.html) applied to the standards set:

- **Major** — a rule is removed or reversed; downstream repos may now be non-compliant.
- **Minor** — a rule is added, or an existing one materially tightened.
- **Patch** — wording, links, typos; no change to what is required.

## [Unreleased]

Nothing yet.

## [0.5.0] — 2026-08-29

### Added — `standards/` (v0.5.0)

**Closing something is not done until every document that assumed the old state moves with it.**
Ownership was already defined; nothing said what maintaining it costs at the moment state
changes.

- `standards/VERSION` — `0.4.0` → `0.5.0`. Minor: a rule is added. Nothing written under `0.4.0`
  becomes invalid, but a repository that closed items without sweeping now has debt it can see.
- `standards/08-keeping-documents-current.md` — new standard. The rule, the surfaces a closure
  obliges, generated views as views rather than sources, the stale-reference sweep keyed on the
  identifier [`04`](./standards/04-documentation-layout.md) makes permanent, the commit
  convention that records the sync, and the `TODO(...)` debt marker for a surface that genuinely
  cannot be updated in the same commit.

  The marker is deliberately narrow. It covers a generator that will not run, not a decision to
  finish the sync later — that deferral is the failure the standard exists to prevent.

- `README.md` — the standards table gains its row.

## [0.4.0] — 2026-08-27

### Added — `standards/` (v0.4.0)

**Cost to reverse is a first-class field on every ADR**, not only the admission test and a column
in the options table.

- `standards/VERSION` — `0.3.0` → `0.4.0`. Minor: a rule is added, and a record written under
  `0.3.0` is now missing a required field.
- `standards/05-decision-records.md` — new **Cost to reverse** section defining the scale
  `Reversible | Costly | One-way`, and the header field carrying it with a clause naming what
  makes it that. The admission test is restated against the scale: anything above `Reversible`
  needs a record.

  Four rules keep the field honest. Rate the **shipped** state rather than the branch, because a
  clean revert today is a backfill the moment it reaches production. The header rating is of the
  **chosen** option and must match that option's row in the table — a header and a table that
  disagree leave the reader unable to tell which is wrong. A `One-way` record names its **escape**
  in Consequences, so the next reader inherits the exit rather than rediscovering there is none.
  And the rating is **never edited as costs rise** with accumulated data: it records the cost as
  at the decision date, and correcting it would destroy the evidence of what was known then. A
  decision that has hardened past its rating is a new record, not an amended one.

- `templates/docs/adr/README.md` — index gains a **Cost to reverse** column, and the instruction
  to read the `One-way` rows first: they are the constraints the codebase has already committed
  to, and the rest is context that can wait.
- `templates/docs/adr/0001-example.md` — header field filled in as a worked example; the chosen
  option marked in the options table so the match between the two is visible.
- `templates/PULL_REQUEST_TEMPLATE.md` — cost-to-reverse prompt under Blast radius, so the
  question is asked at review time and not only when someone remembers an ADR is due.

**Records predating adoption.** No repository consumed `0.3.0`, so nothing is upgrading between
versions — but a repository adopting these standards may arrive with ADRs of its own. Backfill a
rating only where the answer is still knowable from the record. Where it is not, leave the field
absent: a missing rating reads as unknown, an invented one reads as fact.

## [0.3.0] — 2026-08-13

### Added — `standards/` (v0.3.0, the initial set)

Nothing has been released to a consuming repository yet, so this is the first version any
downstream repo will ever see — one block rather than a `0.1.0` → `0.2.0` → `0.3.0` history
describing states that only ever existed upstream.

- `standards/VERSION` — `0.3.0`.
- `standards/00-response-and-collaboration.md` — density not brevity; where to go wide; the
  calls that are never decided silently (public contract, architecture shape, data integrity).
- `standards/01-architecture-defaults.md` — multi-tenancy as a first-class concern, read/write
  separation, result types for expected failure, idempotency for money, designing for contention.
  Departures are recorded as ADRs rather than argued per review.
- `standards/02-database-standards.md` — **the rules**: exact types for money, tenant predicate on
  every scoped query, isolation stated never assumed, SARGability, deliberate indexing including
  last-page insert contention, partitioning and archival, migrations, and verification from the
  plan rather than intuition. Links the review baseline; does not restate it.
- `standards/03-engineering-hygiene.md` — style settled by configuration, git discipline, secrets,
  compliance as a design constraint, real-database testing, dependencies.
- `standards/04-documentation-layout.md` — where documents live, and **planning item
  identifiers**: one identifier per item, assigned by the document that defines it; identifiers
  are permanent and never renumbered; downstream documents cite the owning document's identifier
  rather than minting a parallel scheme; where two schemes already exist, the mapping is recorded
  in the owning document with each row marked confirmed, inferred or unknown, rather than resolved
  by assertion.

  Written in response to a real failure: a backlog acquired a second identifier scheme in a
  session handoff, and a later session could not tell which items the handoff's numbers referred
  to. The rules are shaped by that.

  This was the first file written under `standards/`, and it establishes the **read-only
  vendoring header** that every other file in the set opens with verbatim.
- `standards/05-decision-records.md` — ADRs in `docs/adr/`, required by **cost to reverse** rather
  than importance; options-considered is mandatory; superseded never edited or deleted.
- `standards/06-review-standards.md` — the two axes (Standards and Spec) kept deliberately
  unmerged, and the order in which missing something is expensive. Points at the database review
  baseline rather than duplicating it.
- `standards/07-repo-layout.md` — directory shape, naming, and the strict conventions/context
  division that lets this repository be public.
- `standards/reference/dotnet-sql-baseline.md` — the .NET/SQL review checklist, previously
  reachable only through a machine-local skill directory, and part of the synced set from the
  outset.

  **Why it lives here.** `02` owns the rule; the baseline owns the detection procedure for that
  rule. Kept in separate repositories nothing would make them drift visibly: `02` could tighten a
  rule while the checklist that catches breaches of it stayed put, and no PR would show the gap.
  Vendored together, a rule change and its detection change land in the same sync and are covered
  by the same `VERSION`.

  **Why `reference/` and not `08`.** It is not a peer of the numbered standards. `02` says what
  must be true; this says how to notice that it is not. Numbering it would collapse a distinction
  `06` is explicit about.

  Two lines describing the review harness — how the file is fed to a sub-agent, and a named
  tooling profile — were left behind in the skill that owns that behaviour. They were mechanism,
  not convention.

### Added — sync machinery

- `scripts/Sync-Standards.ps1` — mirrors `standards/` from upstream, deletions included, so the
  local set cannot accumulate files upstream has retired. Resolves its target and **refuses to
  run if it is not inside the repository root**; never commits, pushes or merges. Tested against
  a fixture upstream: added/changed/removed files, idempotent re-run, `-WhatIf` leaving disk
  untouched, an unrelated file outside `standards/` verified intact, and a bad ref failing loudly.
- `.github/workflows/standards-sync.yml` — copied into consuming repos. Weekly cron plus
  `workflow_dispatch`; opens or updates a single `standards-sync` PR, never auto-merges. Fetches
  the sync script from upstream at run time rather than vendoring it, so a fix to the script
  reaches every consumer without needing its own sync.
- `.github/workflows/verify-standards.yml` — runs here: PowerShell parse check, leak guard,
  integrity check, and a pull-request gate failing any change to `standards/**` that did not bump
  `standards/VERSION` — without the bump the change lands downstream with no version signal.
- `scripts/Test-StandardsIntegrity.ps1` — vendoring header on every standard, valid semver,
  resolvable relative links, ADR index consistency. Excludes `templates/`, whose links are
  written to resolve after seeding and are correctly broken in place.

### Added — `templates/` (seeded once, never synced)

- `AGENTS.md.template` — project context plus the path → domain-doc routing table, and an
  explicit table for recording deliberate departures from a standard with the deciding ADR.
- `docs/adr/README.md` and `docs/adr/0001-example.md` — ADR index and a worked example written
  out in full rather than left as headings, because an empty template teaches the format but not
  the standard of evidence.
- `docs/ai/domains/_template.md` — domain vocabulary, invariants (each labelled with what
  enforces it, or nothing), boundaries, open questions and rulings.
- `PULL_REQUEST_TEMPLATE.md` — the two review axes, data-integrity and migration checklists,
  blast radius.

### Added

- Repository scaffolding: `.editorconfig`, `.gitattributes`, `.gitignore`, MIT `LICENSE`.
- `scripts/Test-NoProprietaryLeak.ps1` — CI guard enforcing the convention/instance boundary.
  Deny list is stored as SHA-256 digests so the guard does not publish the names it excludes.
  It scans what could actually reach the remote — `git ls-files --cached --others
  --exclude-standard`, tracked files plus untracked ones git is not already ignoring — rather
  than walking the filesystem, which reported gitignored local working state as a leak and so
  made the gate one you learn to dismiss. The walk survives as a fallback outside a checkout.
- `AGENTS.md` governing work on this repository.
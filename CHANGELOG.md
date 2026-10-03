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

## [0.7.0] — 2026-10-01

> **Minor — `standards/VERSION` `0.6.0` → `0.7.0`.** Rules are added; nothing written
> under `0.6.0` becomes invalid.

### Added — `standards/`

**Seven standards earned from one repository migration.** Each was written from a wrong answer that
looked right at the time, which is why every entry below carries the reasoning and not only the
title — the reasoning is the part that makes a rule stick.

- `standards/08-keeping-documents-current.md` — **"write what will still be true"**, the preventive
  half of the existing rule. The old rule says a closure must sync every surface that assumed the old
  state; this says do not write the sentence that will need the sync. Counts, exhaustive rosters and
  versions restated in a second place are claims with expiry dates, and they fail silently — no build
  breaks when they drift, so they rot while still reading authoritatively and a reader cannot tell a
  current figure from a stale one. Carries the substitution table (count → shape, roster → the rule
  that decides membership, restated value → pointer), the one-question test — *would adding one
  ordinary new thing make this false?* — and the two numbers that are correct and stay: a figure in a
  dated record, where freezing it is the point, and a threshold that drives behaviour, where the
  number *is* the rule.

- `standards/09-durable-references.md` — **no absolute paths, no volatile numbers.** Both rules exist
  because a written-down fact outlives the conditions that made it true, and a stale fact is worse
  than an absent one because it gets believed. An absolute path is silently wrong after any relocation
  rather than loudly broken, so it survives review and fails later. Scoped to every artefact a human
  or agent may read as authoritative, durable agent memory included; run logs are deliberately out of
  scope, because freezing one moment is their whole purpose.

- `standards/10-repository-and-worktree-layout.md` — **the base checkout is named `root`, worktrees
  are its siblings, and the base is never worked on directly.** The base exists to track and
  synchronise with the remote; work happens beside it. Settles, once, which directory is safe to
  commit in.

- `standards/11-evidence-and-verification.md` — **"absence from a page is not absence".** A
  paginated, truncated or filtered reply is evidence about *that reply*, not about the set it came
  from, so no absence may be concluded from it. Read the truncation signal — `hasMore`, `nextCursor`,
  a `totalCount` larger than the items returned — **before** the contents, because the content is
  more interesting than the envelope and so the envelope is what gets skipped. Confirm absence by
  addressing the thing directly, by name or identifier or path: a direct request gives a definite
  answer, whereas failing to find something in a list only tells you about the list.

  Distinct from 11.1, and that distinction is the reason it earns a section: there the harness
  misled you, here the tool answered **accurately and completely** and the error was entirely in the
  reading. A default page size was chosen by whoever wrote the interface for their own convenience,
  and a page boundary falls wherever the data happens to sort — so an entire category can sit just
  past it with nothing in the output hinting at that. It bites hardest on the claims most worth
  getting right: a capability is missing, a file is gone, a record was never written, a server is not
  loaded, a dependency is absent. All five are claims about a *set*, and all five get made from one
  page. Carries the worked example that produced it, in which a catalogue reply of twenty entries
  next to `totalCount: 225` and `hasMore: true` was read as proof that a server did not exist.

- `standards/11-evidence-and-verification.md` — **what counts as proof.** Verify from the correct
  harness: a check run from the wrong place fails for reasons unrelated to the thing being checked,
  which once reported an entire set of good backups as broken. Look for a rename before concluding a
  file is absent. Never infer from an adjacent line. Confirm a dry run's destination. A snapshot is
  never the source of truth. And the one that cost the most: **a successful bind is not proof of
  reachability** — a process can hold a socket that nothing can actually reach.

- `standards/12-data-handling-and-boundaries.md` — **databases, boundaries and secrets.** Never copy
  an open database; never put one across an interoperability boundary. Line-ending policy belongs in a
  committed attributes file, not a per-machine client setting that travels with the person instead of
  the repository. **Cleanliness can be a property of the platform you asked** — the same repository
  reports entirely different modified files depending on which side of a boundary you read it from,
  and that reading describes the asker rather than the repository. Ownership over exemption; secrets
  do not live in sandbox roots.

- `standards/13-concurrent-agents-and-working-memory.md` — **one writer per file, whole-file
  writes.** Concurrent agents sharing a working-memory file corrupt it by interleaving partial
  writes; the fix is ownership, orchestrator-issued session identifiers in the filename, and
  rename-into-place, not locking discipline nobody follows. Carries the
  detour rule and the reminder that a snapshot is not working memory.

- `standards/14-agent-working-directories-and-file-placement.md` — **where an agent puts things.**
  Provider working directories are links into one `agents/` folder, which makes the whole set
  enumerable, movable and backup-able instead of scattered through a user profile. Files worth
  keeping — only what standards 04, 05 and 07 do not already own — go in the active worktree's
  `documents/`; create a worktree if none exists, or use `${dev-root}/documents` when there is no
  repository work — and never a base checkout. Scratch goes to a `.temp/` subfolder and is deleted when
  the task finishes, because "later" does not arrive. Every location is expressed relative to a
  single configured development-root value, so a relocation changes one value and nothing else: that is
  how a standard about locations complies with 09 forbidding absolute paths, and the document says so
  rather than leaving a reader to spot the tension.

- `standards/16-working-memory-protocol.md` — **three working-memory surfaces and one ordered rule
  that picks between them.** Ask in order, first yes decides: would this still be true in a different
  repository six months from now (→ the vault); does it describe work in flight across more than one
  repository (→ the initiative file); otherwise (→ that repository's context). Ordered so two agents
  agree, total so no fact has nowhere to go, and asked about the *fact* rather than about who found
  it. Carries the tie-breakers that actually come up, including the one that matters most: a durable
  convention discovered *during* cross-repo work goes to the vault, because the finding outlives the
  initiative that produced it.

  The spine is the snapshot rule. Both obvious designs failed identically — materialised once, never
  re-derived. The rendered context file is overwritten wholesale on every prompt submission, so
  **agents never write it**; it surfaces agent state by naming the directory, never by restating the
  list, because a restated list is a second copy that goes stale the moment its owner amends the
  first. The task board is **recorded as failed, not qualified**: it shows the items that existed
  when work was scoped and never moves when a finding causes a detour.

  Writes are **single-writer-per-file** — one file per agent, named from its session start and agent
  identity, read all, write one. Copy-edit-merge-delete was rejected on two specific grounds: its
  merge is an unguarded read-modify-write, so concurrent merges silently discard one another, and a
  crash mid-merge leaves an orphan that no reader can classify. Files **accumulate across prompts**
  until items are completed out, never reset per prompt, and anything closed by a detour carries the
  drop reason as a required field.

  The **detour rule**: update your own file whenever a finding changes the remaining work, not only
  at prompt boundaries, because findings do not arrive on prompt boundaries. Amend with a one-clause
  reason, or close out with the reason it was dropped — and never leave an item silently wrong, which
  is the only state where the file actively misleads rather than merely being incomplete.

  Adds the tier that was missing: **cross-repository work in process**, which previously had nowhere
  to live — a wide migration would otherwise have become one partial copy of the same story per
  repository. Its progress is **derived, never stored**: no percentage, no counts, no "N of M", because
  a stored figure is the same defect in miniature. And it inherits the one-way dependency from
  standard 15 — an initiative may reference a repository's context, but a repository's context must
  never reference an initiative, so archiving an initiative breaks nothing.

  Its single-writer section **defers to standard 13** for the mechanism rather than restating it: the
  session identifier is an orchestrator-issued nonce and not a timestamp, writes are renamed into
  place, and reconciliation is a reader's job. Stated explicitly because an earlier draft named the
  file from a session *start*, which is a timestamp and therefore contradicted 13.1 rather than
  merely omitting it. Where the two appear to differ, 13 governs.

- `standards/15-workflow-and-plan-pair.md` — **recurring work produces a workflow *and* a plan, and
  the dependency runs one way.** The plan may reference the workflow; the workflow must never
  reference the plan. The workflow is durable and the plan is disposable, so a workflow pointing at a
  specific plan rots the moment that plan is completed or deleted — losing reusability, the only
  property it had. This is the documentation form of the snapshot rule already in this set: the thing
  that must survive cannot depend on the thing that is meant to go stale. Producing only a plan is
  the failure mode, because the knowledge then dies with the task.

### Added — templates/

Suggestion-only notes for optional agent tooling — APM, agentrc, AGT, and
Perseus/Vault. Seeded once, never synced. `standards/` is unchanged and does
not require any of them.

Perseus/Vault is **optional for consumers**. This kit repo may still use
Perseus as its own project tooling; that is project context, not a mandate.

- `templates/AGENTS.md.template` — Optional: Perseus / Vault (delete if the
  host does not have the stack). Tiny optional-tooling pointer for APM,
  agentrc, AGT as well.
- `templates/perseus/` — optional `context.md` / `pack.yaml` seed.
- `templates/docs/ai/perseus-vault.md` — recommended wiring only when present.
- `templates/docs/ai/optional-agent-package-manager.md` — APM as watch-list or
  third-party side channel; never a second writer on a live canonical tree.
- `templates/docs/ai/optional-agentrc.md` — readiness scores may mis-score
  junctioned/vendored setups; do not overwrite authored `AGENTS.md`.
- `templates/docs/ai/optional-runtime-agent-governance.md` — AGT for money,
  send-on-behalf, destructive tools, fleets; not required for everyday coding
  agents with host-level review. Pilot one host first.

## [0.6.0] — 2026-09-17

### Added — `standards/` (v0.6.0)

**Five git discipline rules that the session-sync gap exposed.** The existing rules
covered what to write into history; these cover how to handle the branches, the
working tree, and unfinished work around it.

- `standards/VERSION` — `0.5.0` → `0.6.0`. Minor: five rules added. Nothing written
  under `0.5.0` becomes invalid.
- `standards/03-engineering-hygiene.md` — five additions to the **Git** section:

  **Branch deletion safety.** A branch is only safe to delete once `git merge-base
  --is-ancestor` confirms it carries zero unique commits. Use `git branch -d`, never
  `-D` (let git refuse rather than force-lose work). Record the SHA of anything deleted
  so it remains recoverable from the reflog.

  **PR containment sequencing.** Work out the containment DAG across every branch pair
  (`git merge-base --is-ancestor`) before opening PRs. Open them oldest-first along it.
  A PR merged out of order cannot be cleanly reverted — the merge record prevents
  re-merging silently once the branch is reverted.

  **Stash discipline.** Resolve every stash before the session ends — pop it, or commit
  it. Inspect first with `git stash show --include-untracked --stat`; a stash holding
  only git-ignored local files can be popped and dropped. A parked stash is uncommitted
  work that the next session will not know about.

  **Agent sessions work in a worktree.** An editor holding `.git/index.lock` blocks
  every index-writing command in that repository, and an agent reached through a sandbox
  frequently cannot clear the lock. A worktree under `.agents/worktrees/` has its own
  index and HEAD against the same object store, so the collision cannot arise — and a
  human's in-progress work cannot be swept into an agent's commit.

  **`core.fileMode` off, `.gitattributes` vendored unedited.** A repository read through
  a second filesystem — container mount, WSL, network share — otherwise reports every
  tracked file as rewritten on line endings and mode bits, which is indistinguishable
  from real uncommitted work and is exactly what `git add -A` commits.

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

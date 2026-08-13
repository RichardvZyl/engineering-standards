<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# 06 — Review standards

## What review is for

Anything a machine can check, a machine checks — formatting, analyzer diagnostics, tests,
coverage, secret scanning. Review spends its attention on what the build cannot see: whether the
change is **correct under concurrency**, whether it **does what was asked**, and whether it
leaves the system easier or harder to change.

A review that produced only style comments did not happen.

## The two axes

A change is reviewed on two axes, and they are **not merged into one verdict**:

| Axis | Question | Source of truth |
|---|---|---|
| **Standards** | Does it follow the conventions, the ADRs, and the database review baseline? | This standards set; `docs/adr/` |
| **Spec** | Does it do what the issue or plan item actually asked for? | The planning item ([`04`](./04-documentation-layout.md)) |

Keeping them separate is the point. A change can be immaculate and solve the wrong problem; a
change can be exactly right and breach a convention that matters. Collapsing both into "looks
good" loses which one was assessed — and in practice the Spec axis is the one that gets skipped,
because the diff is in front of the reviewer and the requirement is not.

Where the work came from a plan, **the item's acceptance criteria are the spec**. Review against
those, not against a recollection of the conversation.

## The database checklist lives elsewhere

[`02`](./02-database-standards.md) owns the database **rules**. The procedure for spotting a
breach of them in a diff — the symptom-level checklist — is
[`reference/dotnet-sql-baseline.md`](./reference/dotnet-sql-baseline.md), vendored alongside the
standards it detects.

**This file points at that baseline; it does not reproduce it.** Two copies of a checklist means
one of them is wrong and no reader knows which.

It lives under `reference/` rather than taking a number because it is not a peer standard. `02`
says what must be true; the baseline says how to notice that it is not. Vendoring them together
is deliberate: a rule that tightens and a detection procedure that does not would otherwise drift
apart silently, in separate repositories, with nothing to make the gap visible.

## What a reviewer looks for first

In order, because this is the order in which missing something is expensive:

1. **Data integrity** — money handled as an exact type, a tenant predicate on every scoped query,
   transaction boundaries visible, isolation stated.
2. **Concurrency** — what happens when this runs twice at once, or when the caller retries after
   a timeout that arrived after the commit.
3. **Blast radius** — what else touches this table, this contract, this queue.
4. **The spec axis** — does it satisfy the acceptance criteria as written.
5. **Change cost** — will the next person extending this have to understand all of it.

## Conduct

- **Comment on the change, not the author.** State the problem and, where you have one, the fix.
- **Distinguish blocking from non-blocking.** An unlabelled review is a review the author has to
  guess at; say plainly which comments must be resolved before merge.
- A reviewer who does not understand a change **asks rather than approves**. An approval that
  means "I skimmed it" is worse than no review, because it consumes the slot a real one would
  have had.
- **Disagreement escalates to a decision, not to seniority.** If it is hard to reverse, it becomes
  an ADR ([`05`](./05-decision-records.md)).

## Self-review

Before requesting review, read your own diff as a stranger would and ask only: *would this
sentence, this method, this migration still be right in six months, in someone else's hands?*
Most of what a reviewer would have caught is visible in that pass.
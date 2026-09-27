<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# 08 — Keeping documents current

A ruling recorded in one document and stale everywhere else is worse than no ruling: it forks
the truth, and the next reader cannot tell which copy is current.

## The rule

**Closing anything — an open question, a decision, a plan item, an external issue — is not done
until every document that assumed the old state is updated in the same commit or pull request.**

Everything below is that rule's shape: what a closure obliges, how to find what it touched, and
what to do when a surface cannot be updated yet.

## What a closure obliges

The owning document is never the only surface.

| When this closes | What moves with it |
|---|---|
| An open question is ruled | The entry, carrying the ruling and its date · every document that stated the provisional default · any decision record whose status or content the ruling changes · the plan, where it changes shape, budgets or defaults |
| A decision record changes status | The record itself · any evaluation table carrying its verdict · any document whose selections hang off it · generated views of the structure it describes |
| A plan item completes, splits or is re-scoped | The item and its status · the dependency view · any budget or capacity summary · the resume checkpoint, if the next step moved |
| A milestone is reached or re-dated | The roadmap · any parent document tracking phase state · generated timeline views |
| An external issue closes | Whichever document owns that concern, then the sweep |

That is the common set, not a closed list. The test is the rule itself: did anything assume the
old state?

## Generated views are regenerated, never hand-edited

A diagram, board or chart derived from a document is a **view**, not a source. Encoding a
decision by editing the view directly creates a second source that disagrees with the first and
says nothing about which is newer. Edit the source, regenerate, and record the new location if
it moved.

## The stale-reference sweep

Before committing a closure, grep the closed item's identifier across the documentation tree and
fix every hit:

```sh
git grep -n "<identifier>" -- docs/
```

The identifier is the one its owning document assigned ([`04`](./04-documentation-layout.md));
that permanence is what makes the sweep possible at all. The passing state is the identifier
appearing only where it is defined and where it is deliberately cited as an example.

Provisional language near a hit — "assumed", "provisional", "for now", "pending" — is worth
chasing even when the identifier itself reads correctly. It is how a superseded default survives
a sweep that only matched on identifiers.

## Write what will still be true

The cheapest way to keep a document current is to not write the sentence that ages. A count, a
roster or a restated version embedded in prose is a claim with an expiry date: correct the day it
is written, wrong the first ordinary time something is added. Nothing fails when it goes wrong —
no build breaks, no test reddens — so it rots in place while still reading authoritatively, and a
reader has no way to tell a current figure from a stale one.

**Prefer the shape to the census.** Three forms carry the same meaning without the expiry:

| Instead of | Write |
|---|---|
| a count — "the twelve modules", "you will not remember all 26" | the shape — "every module", "you will not remember them all" |
| a roster that has to be exhaustive to be correct | the rule that decides membership, and let the reader derive it |
| a version, path or identifier restated in a second place | a pointer to the one place that holds it |

The test, applied to a sentence before it is committed: **would adding one ordinary new thing make
this false?** A new module, a new record, a new environment. If it would, the sentence is a
maintenance obligation nobody scheduled, and the sweep above is what pays for it later.

Two kinds of number are correct and stay. A **dated record** — a changelog entry, a decision
record, a report — where the figure is history and freezing it is the point. And a **threshold
that drives behaviour** — a retry limit, a review quorum, a size budget — where the number *is* the
rule rather than a description of the world. The distinction is whether the number is a measurement
or a decision.

## Commit convention

One closure is one commit, and the message names what closed and what was synced with it:

```
docs: close <identifier> (<the ruling>) — sync <the surfaces touched>
```

Several closures decided in one sitting may share a commit; name each in the body. The message
is the audit trail — it is how a later reader confirms the sync happened instead of assuming it.

## When a surface cannot be updated yet

If a surface genuinely cannot be updated in the same commit — a generator that will not run, a
system that is unavailable — the commit still lands with every other surface synced, plus a
marker at the stale one recording the debt:

```
TODO(<what is stale>): regenerate after <the closure>
```

The marker is the debt record, and it is what makes the gap findable. **No outstanding markers**
is the definition of synced; a repository that cannot say which of its surfaces are stale does
not know whether it is.

Deferring the whole sync to a later session is not this. Recording a closure and leaving its
consequences for next time is the failure this standard exists to prevent, and a marker is not a
licence to do it.

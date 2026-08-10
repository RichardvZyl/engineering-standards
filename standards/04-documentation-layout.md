<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# 04 — Documentation layout

Where documents live, and which document owns what.

## Planning documents

A planning document — a backlog, an expansion matrix, a wave plan, a roadmap — **owns the items
it defines**. Owning them means it assigns their identifiers and is the place those identifiers
are looked up.

Planning documents live in `docs/`. Run artifacts produced by executing a plan live under
`docs/planning/`, never in an agent-state directory such as `.claude/`.

## Item identifiers

**Every planning item has exactly one identifier, assigned by the document that defines it.**

That single rule prevents the failure this standard exists for. Everything below is its shape.

### Form

```
[<group>·]<category><ordinal>
```

- **`<category>`** — one or two letters grouping items by kind. The owning document declares
  what each letter means, in the document, near the items. A letter whose meaning is only in
  someone's head is not a category.
- **`<ordinal>`** — an integer, unique within its category in that document.
- **`<group>`** — optional prefix for a batch, phase or wave (`W5·S2`). Use it only when more
  than one batch is in flight; a prefix that is always the same is noise.

### Rules

**An identifier is permanent.** Once written down it is never reused for a different item and
never renumbered — not to close a gap, not to reorder, not when an item is dropped. A dropped
item's identifier is retired and its row is kept with its status. Renumbering silently
invalidates every document, commit message and conversation that cited the old number.

**Ordinals record insertion order, not priority.** Priority is a column. An identifier that
encodes priority has to change when priority changes, which the rule above forbids.

**A downstream document cites the owning document's identifier; it never mints its own.** A
handoff, checkpoint, session note or commit message refers to `S2`, not to a parallel scheme
invented while writing the handoff. Two schemes for one set of items is the failure mode — the
second scheme is usually created by a reader who did not have the owning document open, and it
diverges immediately.

**When two schemes already exist, record the mapping in the owning document. Do not silently
pick one.** Write the table, mark each row confirmed or inferred, and mark unmappable
identifiers unknown. A contradiction between planning documents is information; resolving it by
assertion destroys that information and produces a mapping nobody can check. Deprecate the
losing scheme explicitly, in the owning document, so the next reader does not re-derive it.

**Commit messages and branch names cite the identifier.** It is the join between the plan and
the history, and it is the reason the identifier has to be stable.

### Status belongs beside the item

An item's status lives in the owning document, in a column, not in a separate tracking file that
drifts from it. A reader who has the plan open must be able to see what is done without opening
anything else.

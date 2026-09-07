# WTDR item-prefix convention

This is a **seeded template snippet** for the *owning* planning document in a consuming repo.
Paste (and edit) it into the doc that defines your planning items so readers have one place to
look up the meaning of each identifier prefix and how items relate to each other.

Generic identifier rule: `standards/04-documentation-layout.md`
(identifier shape + "owning document declares letter meaning").

## 1. Hierarchy

Planning items form a two-level tree. **Workstreams** are the top level; **Tasks** are
children of a workstream. **Decisions**, **Risks**, and **Follow-ups** cross-cut
workstreams — they may affect several, or none.

```
W  Workstream          (scope container — what and why)
└─ T  Task             (executable unit — how and when; belongs to exactly one W)

D  Decision / divergence   (cross-cutting — may touch multiple W's)
R  Risk / assumption       (cross-cutting — may touch multiple W's)
H  Follow-up / consequence (register — may gate or reframe W/T/D)

B  Blocker                 (gate — may sit at any level; always above what it blocks)
```

A workstream without tasks is a placeholder. A task without a parent workstream is
homeless — assign it or promote it.

Follow-ups (`H`) are consequences, open questions, or newly surfaced issues raised
during a rulings or planning session. They live in a **register document** (typically
`OPEN-QUESTIONS.md`), grouped by session/topic sections (`§A`–`§L`, etc.), and referenced
as `§<section>.<ordinal>` (e.g. `§H.6`).

## 2. Blockers

A **blocker** is a hard gate: work it names must not start (or must not finish) until the
blocker is cleared.

**Blockers may live at any level of the hierarchy** — on a workstream, a task, a decision,
a risk, a follow-up, or as a dedicated `B` item. What they share is position, not letter:

> **A blocker is always on top of every item it blocks.**

In the owning document that means:

- the blocker is listed **above** the items it gates (section order, DAG layer, or explicit
  "Hard gates" block before the items it constrains);
- every blocked item is named on the blocker's `blocks:` list;
- blocked work does not start until the blocker reaches a cleared status.

`dependsOn` orders peer work that may already be eligible. `blocks` / `blockedBy` are
different: they are **eligibility gates**, not sequencing among already-unblocked items.

### Who owns the link

The **blocker owns the authoritative `blocks:` list**. A blocked item may mirror
`blockedBy:` for readability; if the two disagree, the blocker's list wins and the
mismatch is recorded (do not silently pick one — same rule as identifier-scheme
conflicts in `standards/04`).

### Clearing a blocker

Closing a blocker is a DOC-SYNC event (`standards/08`): update its status, sweep every
identifier it listed under `blocks:`, and update any mirrored `blockedBy:` fields in the
same commit or PR.

## 3. Identifier shape (what the standards require)

```
[<group>·]<category><ordinal>
```

- **`<category>`** — the letter(s) from the table below: `W`, `T`, `D`, `R`, `H`, `B`.
- **`<ordinal>`** — integer, unique within its category in that document.
- **`<group>`** — optional workstream prefix when tasks need scoping across workstreams
  (e.g. `W5·T3` = task 3 inside workstream 5). Use the group form only when a flat `T`
  sequence would be ambiguous — a single plan with one task sequence does not need it.

**Rules (from `standards/04`):**
- Identifiers are **permanent** — never reused, never renumbered.
- Ordinals record **insertion order**, not priority. Priority is a column.
- A downstream doc **cites** the owning doc's identifier; it never mints a second scheme.

## 4. Category definitions

Declare these in the owning planning doc, near the items, so the meaning is never only in
someone's head.

| Category | Level | Meaning | Typical IDs |
|---|---|---|---|
| `W` | Top | **Workstream** — a named scope of related work with its own acceptance sketch | `W1`, `W2`, … |
| `T` | Child of `W` | **Task** — an executable, independently verifiable unit of work inside a workstream | `T1`, `T2`, … or `W3·T1` |
| `D` | Cross-cutting | **Decision / divergence** — a ruling that changes or settles an earlier position | `D-01`, `D-02`, … |
| `R` | Cross-cutting | **Risk / assumption** — a named threat or unverified premise that gates or constrains items | `R1`, `R2`, … |
| `H` | Cross-cutting (register) | **Follow-up / consequence** — an open question, consequence, or issue raised during a session; lives in a register doc grouped by topic sections | `§H.1`, `§H.6`, `§J.13`, … |
| `B` | Any (always above blocked items) | **Blocker** — a dedicated hard gate whose only job is to block named items until cleared. Prefer `B` when the gate is not already a `D`/`H`/`R`; otherwise put `blocks:` on that existing item | `B1`, `B2`, … or `W2·B1` |

> **`PD` (Proposed Decision)** is a common variant of `D` used while a decision is still
> under discussion. When ruled, a `PD` either graduates to `D` or is recorded as ruled
> in-place — the owning doc decides which.

> **`H` identifiers use section-scoped numbering** (`§<section>.<ordinal>`) rather than
> the flat `<category><ordinal>` form. The section letter groups items by session or topic
> (e.g. §A = hosting, §H = consequences from 2026-07-27, §K = access model). Each section
> owns its own ordinal sequence.

If your consuming repo does **not** use `R`, `H`, or `B` as numbered categories, delete
those rows and do not mint identifiers for them — but if something still gates work, put
`blocks:` on the item that actually is the gate (`D`, `H`, open question, etc.).

## 5. Example: copy/paste skeleton for your owning planning doc

Paste and edit near the top of your planning doc, before the items:

```yaml
# <PROJECT>: planning item identifiers
# Owning doc: <DOC_PATH>
#
# Hierarchy:  W (workstream) → T (task)
# Cross-cut:  D (decision/divergence), R (risk/assumption), H (follow-up/consequence)
# Gates:      B (blocker) or blocks: on any item — always listed above what it blocks
# Shape:      [<group>·]<category><ordinal>  — H uses §<section>.<ordinal>
# Rules:      IDs are permanent; ordinals = insertion order; downstream cites, never mints.
```

### Hard gates (always above the items they block)

```yaml
blockers:
  - id: B1
    title: "<What must be true before blocked work may start>"
    status: "<Open|Cleared|Waived>"
    blocks: [T8, T16]          # authoritative list of gated items
    clearance: "<Ruling recorded where, or waiver condition>"

  # A follow-up or decision can also be the gate — same position rule:
  - id: "§H.6"
    title: "<Open consequence that gates work>"
    status: "<Open|Closed|Deferred>"
    blocks: [W4, W9]
```

### Workstreams (top level)

```yaml
workstreams:
  - id: W1
    title: "<Workstream title>"
    status: "<Proposed|InProgress|Done|Dropped>"
    acceptance: "<What 'done' means for this workstream>"
    blockedBy: []              # optional mirror; B*.blocks / H*.blocks win on conflict

  - id: W2
    title: "..."
```

### Tasks (children of a workstream)

```yaml
tasks:
  - id: T1
    workstream: W1
    title: "<Task title>"
    dependsOn: []              # peer ordering among eligible work
    blockedBy: []              # optional mirror of gates above
    status: "<Proposed|InProgress|Done|Dropped>"
    acceptance: "<Objective, checkable criterion>"

  - id: T8
    workstream: W2
    title: "..."
    dependsOn: [T7]
    blockedBy: [B1]            # must not start while B1 is Open
    status: "<Proposed|InProgress|Done|Dropped>"
    acceptance: "..."
```

### Decisions (cross-cutting)

```yaml
decisions:
  - id: D-01
    title: "<What was decided or diverged>"
    status: "<Proposed|Ruled|Superseded>"
    affects: [W2, W5]
    blocks: []                 # non-empty when this decision is itself a hard gate
```

### Risks / assumptions (cross-cutting)

```yaml
risks:
  - id: R1
    title: "<Risk or assumption>"
    status: "<Open|Mitigated|Accepted|Retired>"
    affects: [W3]
    blocks: []                 # non-empty when unresolved risk gates named work
```

### Follow-ups / consequences (register doc, e.g. `OPEN-QUESTIONS.md`)

```yaml
# §H — Raised or reframed on <DATE>
followUps:
  - id: "§H.1"
    title: "<Consequence or open question>"
    status: "<Open|Closed|Deferred>"
    affects: [W5, D-01]
    blocks: []                 # non-empty when this follow-up is a hard gate
```

## 6. Consistency checks

- **Parent link:** every `T` item names its parent `W` (column, YAML field, or section heading).
- **Blocker position:** every item with a non-empty `blocks:` list appears above those IDs
  in the owning doc (or in an explicit Hard-gates section that precedes them).
- **Blocker completeness:** every ID in `blocks:` exists in the owning doc; every mirrored
  `blockedBy:` entry points at a blocker that lists this item (or the mismatch is recorded).
- **Gates ≠ dependsOn:** do not encode a hard gate only as `dependsOn` — use `blocks` /
  `blockedBy` so a reader can see eligibility separately from peer order.
- **Separator style:** pick one form for `D` (`D01` vs `D-01`) and keep it throughout the doc.
- **Retired items:** keep the row with a terminal status; never delete or reuse the ID.
- **Flat vs scoped tasks:** a single plan with one continuous `T` sequence is fine; use
  `W<n>·T<m>` only when multiple plans or phases would collide on bare `T` ordinals.

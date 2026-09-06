# WTDR item-prefix convention

This is a **seeded template snippet** for the *owning* planning document in a consuming repo.
Paste (and edit) it into the doc that defines your planning items so readers have one place to
look up the meaning of each identifier prefix and how items relate to each other.

Generic identifier rule: `standards/04-documentation-layout.md`
(identifier shape + "owning document declares letter meaning").

## 1. Hierarchy

Planning items form a two-level tree. **Workstreams** are the top level; **Tasks** are
children of a workstream. **Decisions** and **Risks** cross-cut workstreams — they may
affect several, or none.

```
W  Workstream          (scope container — what and why)
└─ T  Task             (executable unit — how and when; belongs to exactly one W)

D  Decision / divergence   (cross-cutting — may touch multiple W's)
R  Risk / assumption       (cross-cutting — may touch multiple W's)

H  Follow-up / consequence (raised during a session, tracked in a register)
```

A workstream without tasks is a placeholder. A task without a parent workstream is
homeless — assign it or promote it.

Follow-ups (`H`) are consequences, open questions, or newly surfaced issues raised
during a rulings or planning session. They live in a **register document** (typically
`OPEN-QUESTIONS.md`), grouped by session/topic sections (`§A`–`§L`, etc.), and referenced
as `§<section>.<ordinal>` (e.g. `§H.6`). Unlike tasks, they are not children of a
workstream — they cross-cut the plan and often **gate** or **reframe** items in W/T/D.

## 2. Identifier shape (what the standards require)

```
[<group>·]<category><ordinal>
```

- **`<category>`** — the letter(s) from the table above: `W`, `T`, `D`, `R`, `H`.
- **`<ordinal>`** — integer, unique within its category in that document.
- **`<group>`** — optional workstream prefix when tasks need scoping across workstreams
  (e.g. `W5·T3` = task 3 inside workstream 5). Use the group form only when a flat `T`
  sequence would be ambiguous — a single plan with one task sequence does not need it.

**Rules (from `standards/04`):**
- Identifiers are **permanent** — never reused, never renumbered.
- Ordinals record **insertion order**, not priority. Priority is a column.
- A downstream doc **cites** the owning doc's identifier; it never mints a second scheme.

## 3. Category definitions

Declare these in the owning planning doc, near the items, so the meaning is never only in
someone's head.

| Category | Level | Meaning | Typical IDs |
|---|---|---|---|
| `W` | Top | **Workstream** — a named scope of related work with its own acceptance sketch | `W1`, `W2`, … |
| `T` | Child of `W` | **Task** — an executable, independently verifiable unit of work inside a workstream | `T1`, `T2`, … or `W3·T1` |
| `D` | Cross-cutting | **Decision / divergence** — a ruling that changes or settles an earlier position | `D-01`, `D-02`, … |
| `R` | Cross-cutting | **Risk / assumption** — a named threat or unverified premise that gates or constrains items | `R1`, `R2`, … |
| `H` | Cross-cutting (register) | **Follow-up / consequence** — an open question, consequence, or issue raised during a session; lives in a register doc grouped by topic sections | `§H.1`, `§H.6`, `§J.13`, … |

> **`PD` (Proposed Decision)** is a common variant of `D` used while a decision is still
> under discussion. When ruled, a `PD` either graduates to `D` or is recorded as ruled
> in-place — the owning doc decides which.

> **`H` identifiers use section-scoped numbering** (`§<section>.<ordinal>`) rather than
> the flat `<category><ordinal>` form. The section letter groups items by session or topic
> (e.g. §A = hosting, §H = consequences from 2026-07-27, §K = access model). Each section
> owns its own ordinal sequence.

If your consuming repo does **not** use `R` or `H` as numbered categories, delete those
rows and do not mint identifiers for them.

## 4. Example: copy/paste skeleton for your owning planning doc

Paste and edit near the top of your planning doc, before the items:

```yaml
# <PROJECT>: planning item identifiers
# Owning doc: <DOC_PATH>
#
# Hierarchy:  W (workstream) → T (task)
# Cross-cut:  D (decision/divergence), R (risk/assumption), H (follow-up/consequence)
# Shape:      [<group>·]<category><ordinal>  — H uses §<section>.<ordinal>
# Rules:      IDs are permanent; ordinals = insertion order; downstream cites, never mints.
```

### Workstreams (top level)

```yaml
workstreams:
  - id: W1
    title: "<Workstream title>"
    status: "<Proposed|InProgress|Done|Dropped>"
    acceptance: "<What 'done' means for this workstream>"

  - id: W2
    title: "..."
```

### Tasks (children of a workstream)

```yaml
tasks:
  - id: T1
    workstream: W1        # parent workstream
    title: "<Task title>"
    dependsOn: []
    status: "<Proposed|InProgress|Done|Dropped>"
    acceptance: "<Objective, checkable criterion>"

  - id: T2
    workstream: W1
    title: "..."
    dependsOn: [T1]
```

### Decisions (cross-cutting)

```yaml
decisions:
  - id: D-01
    title: "<What was decided or diverged>"
    status: "<Proposed|Ruled|Superseded>"
    affects: [W2, W5]    # which workstreams this touches
```

### Risks / assumptions (cross-cutting)

```yaml
risks:
  - id: R1
    title: "<Risk or assumption>"
    status: "<Open|Mitigated|Accepted|Retired>"
    affects: [W3]
```

### Follow-ups / consequences (register doc, e.g. `OPEN-QUESTIONS.md`)

```yaml
# §H — Raised or reframed on <DATE>
followUps:
  - id: "§H.1"
    title: "<Consequence or open question>"
    status: "<Open|Closed|Deferred>"
    affects: [W5, D-01]   # which items this gates or reframes

  - id: "§H.6"
    title: "..."
    status: "<Open|Closed|Deferred>"
    affects: [W4, W9]
```

## 5. Consistency checks

- **Parent link:** every `T` item names its parent `W` (column, YAML field, or section heading).
- **Separator style:** pick one form for `D` (`D01` vs `D-01`) and keep it throughout the doc.
- **Retired items:** keep the row with a terminal status; never delete or reuse the ID.
- **Flat vs scoped tasks:** a single plan with one continuous `T` sequence is fine; use
  `W<n>·T<m>` only when multiple plans or phases would collide on bare `T` ordinals.

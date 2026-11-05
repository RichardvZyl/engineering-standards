<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# 00 — Response and collaboration

How an assistant working in this repository should answer. This is the first standard because
every other one is delivered through it.

## The rule

**Density, not brevity — cut words, never options.**

Every sentence carries a claim that can be acted on or disagreed with. No preamble, no restating
the question, no summarising what was just said. If a sentence can be removed without losing
meaning, remove it.

"Concise" governs **wording**. It never governs **coverage**. A short answer that dropped an
option is not concise; it is incomplete.

## Shape of an answer

- **Lead with the answer or recommendation**, then justify it. A conclusion at the bottom is a
  conclusion the reader has to hunt for.
- **Assume depth.** Skip 101-level explanation of the language, the database, DDD, CQRS and the
  like unless it was asked for.
- **Push back when warranted.** Honest technical disagreement is more useful than agreement.
  Agreement that was not earned costs the reader the review they thought they were getting.
- **Prefer correctness under concurrency** over cleverness or brevity of code.

## Output structure and formatting

Every response is structured as a concise architecture brief, not a conversational transcript:

1. **Verdict or action first (1–2 sentences).** Open with what was decided, found, or changed. Omit conversational preambles ("Sure!", "Let me check that"), tool-call narration, and filler.
2. **Clickable links for every file and symbol.** Format file and symbol references as Markdown links using the short basename or relative path as the link text and the target path (with `#Lstart-Lend` line ranges where relevant) as the destination — e.g. `[OrderService.cs](src/Orders/OrderService.cs#L42-L58)` or `[TryReserveFunds](src/Ledger/ReservationEngine.cs#L110-L145)`. Never paste raw full paths as unlinked prose.
3. **Structured Markdown headings and tables over prose.** Use `###` sections (`### Why`, `### Where things live`, `### Recommendation`, `### Verification`) to separate diagnosis, taxonomy, and proof. Use Markdown tables whenever mapping locations, comparing options/trade-offs, or reporting multi-item state.
4. **Verification proof after every change.** State the exact check run (`git check-ignore -v`, `dotnet test`, integrity script, exit code) and the concrete outcome per target.
5. **Fully qualified category names and claim glosses on every identifier.** Whenever citing a planning or decision identifier (`W`, `T`, `D`, `PD`, `R`, `H`, `B`, `ADR NNNN`, or document-declared categories), precede the identifier with its **fully qualified category name** and follow it immediately with a **short claim gloss in brackets** on *every* mention — e.g. `Workstream W1·Task T2 (enforce tenant predicate on read models)`, `Blocker B1 (verify base checkout is clean before creating a worktree)`, `Architecture Decision Record ADR 0004 (mutex is an admission rule, not a dependency edge)`. See [`04`](./04-documentation-layout.md) for the citation rule.
6. **One crisp closing decision or next step.** End with a single direct question or action choice when input is required; never trail off with open-ended pleasantries.

### Example response

~~~markdown
[`.gitignore`](../.gitignore#L30-L33) now ignores repo-level `/.codex/` alongside `/.claude/`, leaving nested workspace snapshots tracked.

### Why it showed up untracked
1. The context renderer stamped both `.claude/settings.json` and `.codex/hooks.json` at the checkout root.
2. [`.gitignore`](../.gitignore#L30-L33) anchored `/.claude/`, but `/.codex/` was omitted when Architecture Decision Record ADR 0015 (agent working state lives in `.agents/`, vendor config stays in vendor dot-folders) split vendor directories out under Workstream W5·Task T3 (isolate harness working state from vendor folders).

### Where things live
| Surface | Canonical location |
|---|---|
| **Repo-level vendor dot-folders** (`.claude/`, `.codex/`) | In-place at checkout root, **gitignored via `/.claude/` and `/.codex/`** in [`.gitignore`](../.gitignore#L32-L33). |
| **Workspace-level `.codex` snapshot** | [`_workspace/.codex/config.toml`](../_workspace/.codex/config.toml) (tracked). |

### Verification (`git check-ignore -v`)
- `.codex/hooks.json` → matched by `.gitignore:33:/.codex/` (ignored at checkout root).
- [`_workspace/.codex/config.toml`](../_workspace/.codex/config.toml) → not ignored (anchored rule leaves nested snapshots intact).

Would you like me to commit the [`.gitignore`](../.gitignore) change on the active worktree branch?
~~~

## Where to go wide

Concise is not shallow. For a **decision, comparison, investigation, or anything left
undecided**, breadth is the deliverable. Go wide on angles, then compress the prose.

- **Name every realistic option**, including do-nothing and defer. An unlisted option is a missed
  one; a wordy option is merely unedited.
- **Per option: upside, downside, and cost to reverse later.** That last one usually decides it,
  and it is the one most often left out.
- **The nuances that actually bite here** — contention and lock ordering, tenant isolation,
  idempotency and retry and partial failure, migration and backfill, data volume and query-plan
  stability, regulatory constraints on personal and financial data. Listing a category that does
  not apply is padding; omit it.
- **Implications:** what breaks if the choice turns out wrong, and when that would be noticed.
  "We would find out at month-end close" is a different risk from "we would find out in CI".
- **Name the winner for this context**, with one line of why.
- **Examples only when they make a comparison decidable** — the exact query shape, lock pattern,
  index or failure interleaving that separates two options. An example that restates an option at
  greater length is filler.
- **Surface assumptions as open questions.** If something had to be assumed to proceed, say so
  and state what changes if it is wrong.

Tables and tight bullets are the preferred shape: they hold many angles in few words.

## Never decide these silently

Some calls are not the assistant's to make quietly, regardless of how obvious they look:

- anything that moves a **public contract** — an API surface, a message schema, a stored
  procedure signature
- anything that changes an **architecture or dependency shape**
- anything touching **data integrity** — money, ledger rows, tenant boundaries, retention

State the assumption, name what you would do, and let it be confirmed. The cost of asking is one
exchange. The cost of a silent wrong call on any of the above is a migration.

## Disagreement and error

Own mistakes plainly and fix them. Do not pad an apology, and do not become more agreeable after
being corrected — the correction is evidence the pushback was worth having, not evidence that
pushback is unwelcome.
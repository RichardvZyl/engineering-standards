# AGENTS.md — working in this repository

This file governs work on **`engineering-standards` itself**. It is not the file a consuming
repo gets; that one is [`templates/AGENTS.md.template`](./templates/AGENTS.md.template).

Read this before editing anything. The failure modes here are unusual, and none of them
announce themselves.

---

## What this repository is

The upstream source of my engineering conventions. `standards/` is vendored into other repos
and kept current by a sync PR. That single fact drives every rule below: **anything you write
under `standards/` will appear, unedited, in repositories you cannot see.**

## The rule that matters most

**The template carries the convention, never the instance.**

A line that names a repo, org, client or product is project context. It belongs in that
project's own `AGENTS.md`, not here. Ask of every sentence: *is this true for any repo I might
apply it to, or only for the one I happen to be thinking about?* If the second, it does not
belong.

Failing examples, all of them things that look harmless while you are writing them:

- naming the internal package family a pattern was extracted from
- an example query against a real schema
- a machine-local path in a code fence
- a workflow that assumes a specific org's runner labels or branch protection

Fixed forms: describe the pattern without the package, invent a neutral schema, use a relative
path, state the requirement the workflow depends on.

This is enforced by `scripts/Test-NoProprietaryLeak.ps1` on every push. **Do not weaken the
guard to make a build pass.** If it fires, the content is wrong, not the guard. The one
legitimate change is adding a token via `-AddToken`; removing one needs a reason recorded in an
ADR.

## Composition — do not write a third copy

Database guidance lives in exactly three places, each with a different job:

| Document | Owns |
|---|---|
| `standards/02-database-standards.md` | **The rule** — what must be true |
| `standards/reference/dotnet-sql-baseline.md` | **The review checklist** — how to spot a breach in a diff |
| `AI-CONTEXT.md` §5 *(public CV repo, external)* | **The public summary** |

`02` states rules and **links** the baseline; it never restates it. `06-review-standards.md`
points at the baseline for the same reason. Where `02` and the public summary disagree, **`02`
wins** and the summary is updated to match — the CV repo is a summary, not a source of truth.

Before adding database content, decide which of the three owns it. If the answer is "all
three", the answer is wrong.

## Editing `standards/`

- Every file under `standards/` opens with the read-only vendoring header, verbatim. A file
  without it will be edited downstream by someone who had no way of knowing better.
- A change to `standards/**` requires a `standards/VERSION` bump and a `CHANGELOG.md` entry.
  The sync PR title is built from `VERSION`; without the bump, downstream sees nothing.
- Each new `standards/` version gets its own dated `CHANGELOG.md` block. **Never fold a rule
  into an earlier version's block**, even pre-release. A rule buried under another version's
  entry is a rule nobody finds when they need to know when it arrived.
- Prefer amending an existing standard over adding a file. Eight files that are read beat
  fifteen that are skimmed.
- Write rules as assertions in the present tense — "Money is `decimal`" — not as advice.
  Advice invites negotiation in a code review; a rule does not.

## Editing `templates/`

The opposite discipline. These are **seeded once and then owned by the consuming repo**, so
they may contain placeholders and instructions to the reader. Mark placeholders unmistakably
(`<PROJECT>`, `<!-- REPLACE: ... -->`) and assume the reader deletes half of it.

## Conventions inherited from the wider kit

- **ADRs live in `docs/adr/`.** Never `.agents/adr/`.
- **Domain docs live in `docs/ai/domains/`**, reached by a path → doc routing table in the
  consuming repo's `AGENTS.md`. There is no `CONTEXT.md` in this world.
- **`pwsh`, never `powershell.exe`.** Scripts here declare `#Requires -Version 7.0` and use
  APIs Windows PowerShell 5.1 does not have. Some tooling defaults to 5.1 — be explicit.
- **Agent working state lives in `.agents/`.** `continue.md`, `worktrees/`, and `temp/` go
  in `<repo>/.agents/`, not `.claude/`. The `.claude/` directory holds only what the vendor
  harness requires (`settings.local.json`, per-repo `commands/`, `agents/`). Both are
  git-ignored at every repo root. (ADR 0015 — `reusable-ai-tools`.)
- **Record known contradictions between planning documents** rather than silently resolving
  one in favour of the other. The contradiction is information.

## Before you open a PR

1. `pwsh ./scripts/Test-NoProprietaryLeak.ps1` — clean.
2. `standards/VERSION` bumped if `standards/**` changed.
3. `CHANGELOG.md` entry added in its own version block, not folded into a prior one.
4. Every relative link resolves.
5. Re-read the diff asking only: *would this sentence be wrong in someone else's repo?*

## Memory and workspace context (Perseus)

### Shared Vault (all repos on this machine)
- Store: resolved at use time from `PERSEUS_VAULT_DB_PATH`, or the per-user default under `~/.perseus-vault/data/`, via the **`perseus-vault`** MCP (`perseus_vault_*` tools). The concrete path is an *input*, never a literal in a document — see standards 09.
- **Read when:** session start (`perseus_vault_context`); before re-deciding something that may already be settled; looking up cross-repo conventions/facts.
- **Write when:** durable facts, decisions, conventions (`perseus_vault_remember`); journal meaningful events. Prefer consolidate related memories over duplicates.
- **Never write:** secrets, credentials, API keys, or session/chat transcripts (use https://perseus.observer/ledger/ for session history if needed).

### Project Context Engine (this repo only)
- Files: `.perseus/context.md` (and `pack.yaml`) via **`perseus`** MCP; edit context then `perseus render` when the briefing changes.
- **Read when:** entering this repo; before planning or implementing work here.
- **Write when:** project-specific status, constraints, architecture notes, and handoff briefing — keep them here, not in the shared Vault, unless they are true cross-repo conventions.
- Do **not** reuse another project's `.perseus` briefing.



## Durable references (standards 09) — two hard rules

**Never write an absolute path.** Not in docs, ADRs, `AGENTS.md`, config, scripts, commit messages or
durable memory. Use repo-relative paths, or a variable/environment indirection resolved at use time.
If a path must be concrete at runtime, it is an *input*, not a literal. Examples obey this too,
because examples get copied.

**Never write down a number that is likely to change.** Record the check that regenerates it, not the
value. File/object/commit counts, byte sizes, hashes, page and table counts, timings — all volatile.
Ports, schema versions and policy limits are structural and may be stated. Measurements belong in a
dated run log; durable text cites the log instead of inlining the figure.

Both rules exist because written-down facts outlive the conditions that made them true, and a stale
fact is worse than a missing one — it gets believed. See `standards/09-durable-references.md` for the
full rationale and the review checklist.

## Perseus: two different components — do not conflate them

Perseus is **two** things. Confusing them wastes time, and has already done so.

**Perseus Vault — this is memory.** A durable entity store (SQLite, full-text index, embeddings),
spoken to as an **MCP stdio server**. Each MCP client launches **its own** vault process, and they all
point at **one shared database** — that is the designed model, not a misconfiguration, so several
concurrent vault processes are expected and correct. Reach for the vault when you need to **remember
something across sessions, or recall what was decided before**. Semantic recall depends on the binary
being built with embedding support; if recall reports unavailable, suspect the binary before the data.

**Perseus Context Engine — this is a renderer.** It resolves a context template into a rendered
context file, expanding directives (memory lookups, shell queries, checkpoints, task boards) into
text. Its state lives in its own per-user directory, **separate from the vault's database**, and it is
a **different binary**. Reach for the Context Engine when you need a **current snapshot of a
workspace** assembled for a prompt.

**In one line:** the **vault stores** what should outlast the session; the **Context Engine composes**
what the next prompt should see. A rendered context file is a snapshot, not a source of truth —
verify anything load-bearing against live tools.

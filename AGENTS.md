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
| `dotnet-sql-baseline.md` *(review kit, external)* | **The review checklist** — how to spot a breach in a diff |
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
- **Record known contradictions between planning documents** rather than silently resolving
  one in favour of the other. The contradiction is information.

## Before you open a PR

1. `pwsh ./scripts/Test-NoProprietaryLeak.ps1` — clean.
2. `standards/VERSION` bumped if `standards/**` changed.
3. `CHANGELOG.md` entry added.
4. Every relative link resolves.
5. Re-read the diff asking only: *would this sentence be wrong in someone else's repo?*
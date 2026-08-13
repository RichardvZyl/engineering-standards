<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# 07 — Repository layout

## The shape

```
<repo>/
  README.md            what this is, how to run it, how to test it
  AGENTS.md            project context and the path → domain-doc routing table
  CHANGELOG.md         if the repository is consumed by anything else
  .editorconfig  .gitattributes  .gitignore

  src/                 production code, one directory per project
  tests/               test projects, mirroring src/ one-for-one

  docs/
    adr/               decision records + README.md index
    ai/domains/        domain vocabulary, routed from AGENTS.md
    planning/          run artifacts produced by executing a plan

  scripts/             build, migration and maintenance scripts
  standards/           vendored from upstream — read-only

  .github/workflows/   CI
```

**The root holds configuration, not content.** A root directory with thirty files has stopped
telling a newcomer anything; the first thing they see should be the shape of the system.

## Rules

- **`src/` and `tests/` mirror one another.** A project without a corresponding test project is
  visible at a glance, which is the point.
- **Documentation lives in `docs/`, never scattered beside the code it describes**, with the
  exception of a README explaining a single directory's contents.
- **`docs/planning/` holds run artifacts**, not agent state. Agent-state directories such as
  `.claude/` are working memory: they are not documentation and are not where a plan is looked up
  ([`04`](./04-documentation-layout.md)).
- **`standards/` is vendored and read-only.** A local edit is drift that the next sync pull
  request will fight. Disagree with a standard? Change it upstream.
- **Generated output is never committed.** If it is generated, it is in `.gitignore`; if it must
  be committed, it is marked generated in `.gitattributes` so it collapses in diffs.

## Naming

- Directories are lowercase and hyphenated; .NET project directories match their project name.
- A name says what the thing **is**, not what layer it sits in. `Ledger` beats `BusinessLogic`.
- **`Common`, `Shared`, `Utils` and `Helpers` are prohibited as project or namespace names.**
  They have no membership criterion, so everything eventually qualifies, and the result is a
  package every other package depends on.

## AGENTS.md

Every repository has one. It carries the things that are **true of this project only** —
domain, tenancy model, engine and version, deployment topology, local setup, the traps — plus a
**path → domain-doc routing table** telling a reader which document governs which directory.

| Path | Domain doc |
|---|---|
| `src/Ledger/**` | `docs/ai/domains/ledger.md` |
| `src/Billing/**` | `docs/ai/domains/billing.md` |

The division is strict, and it is the reason these standards can be public:

- **Conventions** — how we work, applicable to any project — live in `standards/`.
- **Context** — repos, orgs, clients, products, schemas, topology — lives in `AGENTS.md`.

A line that names a repository, organisation, client or product belongs in `AGENTS.md`. If it
appears in `standards/`, it is in the wrong file.
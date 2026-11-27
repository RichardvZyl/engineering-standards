<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# Skills

The numbered file is the rule. A skill is how an agent finds and applies that one rule
without loading the rest of the set.

## How this functions

1. The harness indexes each skill's `description` and nothing else.
2. When the task matches, it loads that `SKILL.md`.
3. The skill's first instruction is to read the standard it names, then apply the steps in order.
4. If the skill and the standard disagree, the standard wins. The skill is fixed upstream
   in the same change. A gate line is a reminder, not a second source.

`standards/` is what the sync pull request mirrors, so this directory arrives downstream
with the rules. It is read-only there, same as every other file under `standards/`.

There is no `references/` copy of a standard. The detection procedure for the database
rules stays in [`reference/dotnet-sql-baseline.md`](../reference/dotnet-sql-baseline.md),
which has its own skill. Two copies is how one of them goes stale.

## Turning them on

Point the harness's skill path at this directory, or link each child into the directory
the harness scans. Link, do not copy. A copy is a fork of the rule.

The upstream repository ships `scripts/Link-StandardsSkills.ps1`, which links each child
into `.agents/skills/` (or a path you pass). A consuming repository that only vendors
`standards/` can do the same thing: one directory link per child of `standards/skills/`,
retargeted if the checkout moves. Do not write the concrete machine path into a document.

## Editing

Change the rule in the numbered file. Change the skill in the same commit when its
trigger, its order of work, or a reminder no longer matches that file. Adding a standards
markdown file outside this directory without a skill fails the integrity check.

## Index

| Skill | Rule |
|---|---|
| [`response-and-collaboration`](./response-and-collaboration/SKILL.md) | [`standards/00-response-and-collaboration.md`](../00-response-and-collaboration.md) |
| [`architecture-defaults`](./architecture-defaults/SKILL.md) | [`standards/01-architecture-defaults.md`](../01-architecture-defaults.md) |
| [`database-standards`](./database-standards/SKILL.md) | [`standards/02-database-standards.md`](../02-database-standards.md) |
| [`dotnet-sql-review`](./dotnet-sql-review/SKILL.md) | [`standards/reference/dotnet-sql-baseline.md`](../reference/dotnet-sql-baseline.md) |
| [`engineering-hygiene`](./engineering-hygiene/SKILL.md) | [`standards/03-engineering-hygiene.md`](../03-engineering-hygiene.md) |
| [`documentation-layout`](./documentation-layout/SKILL.md) | [`standards/04-documentation-layout.md`](../04-documentation-layout.md) |
| [`decision-records`](./decision-records/SKILL.md) | [`standards/05-decision-records.md`](../05-decision-records.md) |
| [`review-standards`](./review-standards/SKILL.md) | [`standards/06-review-standards.md`](../06-review-standards.md) |
| [`repo-layout`](./repo-layout/SKILL.md) | [`standards/07-repo-layout.md`](../07-repo-layout.md) |
| [`keeping-documents-current`](./keeping-documents-current/SKILL.md) | [`standards/08-keeping-documents-current.md`](../08-keeping-documents-current.md) |
| [`durable-references`](./durable-references/SKILL.md) | [`standards/09-durable-references.md`](../09-durable-references.md) |
| [`repository-worktrees`](./repository-worktrees/SKILL.md) | [`standards/10-repository-and-worktree-layout.md`](../10-repository-and-worktree-layout.md) |
| [`evidence-and-verification`](./evidence-and-verification/SKILL.md) | [`standards/11-evidence-and-verification.md`](../11-evidence-and-verification.md) |
| [`data-handling-boundaries`](./data-handling-boundaries/SKILL.md) | [`standards/12-data-handling-and-boundaries.md`](../12-data-handling-and-boundaries.md) |
| [`concurrent-agents`](./concurrent-agents/SKILL.md) | [`standards/13-concurrent-agents-and-working-memory.md`](../13-concurrent-agents-and-working-memory.md) |
| [`agent-file-placement`](./agent-file-placement/SKILL.md) | [`standards/14-agent-working-directories-and-file-placement.md`](../14-agent-working-directories-and-file-placement.md) |
| [`workflow-and-plan`](./workflow-and-plan/SKILL.md) | [`standards/15-workflow-and-plan-pair.md`](../15-workflow-and-plan-pair.md) |
| [`working-memory`](./working-memory/SKILL.md) | [`standards/16-working-memory-protocol.md`](../16-working-memory-protocol.md) |
| [`deploy-artifacts`](./deploy-artifacts/SKILL.md) | [`standards/18-deploy-artifacts-are-not-source.md`](../18-deploy-artifacts-are-not-source.md) |
| [`apply-engineering-standards`](./apply-engineering-standards/SKILL.md) | Router. No rule of its own. |

---
name: apply-engineering-standards
description: >
  Route work in a repository that vendors these standards. Use at the start of any non-trivial change — code, schema, review, docs, git, or agent file placement — to select the one or two skills that apply. Do not load every standard. Triggers: standards, conventions, how we work, before I start, which rule.
metadata:
  role: router
---

<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# Apply engineering standards

Pick the skills that match the task. Read each chosen standard in full before editing.
The numbered file is the rule. The skill is how you find it and the order you apply it.
If they disagree, the standard wins.

Project context — tenancy, engines, commands, names — comes from that repository's
`AGENTS.md`, not from these skills. A departure from a standard is a decision record,
not a silent exception. In a consuming repository, `standards/` is read-only.

## When the result is something a person will read

Also load [`response-and-collaboration`](../response-and-collaboration/SKILL.md),
whatever else you load.

## Which skill

| When | Skill | Rule |
|---|---|---|
| A person will read the result | [`response-and-collaboration`](../response-and-collaboration/SKILL.md) | [`00-response-and-collaboration.md`](../../00-response-and-collaboration.md) |
| New component, tenancy, idempotency, async | [`architecture-defaults`](../architecture-defaults/SKILL.md) | [`01-architecture-defaults.md`](../../01-architecture-defaults.md) |
| Schema, query, migration, money column | [`database-standards`](../database-standards/SKILL.md) | [`02-database-standards.md`](../../02-database-standards.md) |
| Reviewing a data-access diff | [`dotnet-sql-review`](../dotnet-sql-review/SKILL.md) | [`dotnet-sql-baseline.md`](../../reference/dotnet-sql-baseline.md) |
| Commit, secret, test, dependency, delete | [`engineering-hygiene`](../engineering-hygiene/SKILL.md) | [`03-engineering-hygiene.md`](../../03-engineering-hygiene.md) |
| Where a document lives; citing an id | [`documentation-layout`](../documentation-layout/SKILL.md) | [`04-documentation-layout.md`](../../04-documentation-layout.md) |
| A choice that is costly to undo | [`decision-records`](../decision-records/SKILL.md) | [`05-decision-records.md`](../../05-decision-records.md) |
| Review or self-review | [`review-standards`](../review-standards/SKILL.md) | [`06-review-standards.md`](../../06-review-standards.md) |
| Directories, project names, AGENTS.md | [`repo-layout`](../repo-layout/SKILL.md) | [`07-repo-layout.md`](../../07-repo-layout.md) |
| Closing a question, item, or decision | [`keeping-documents-current`](../keeping-documents-current/SKILL.md) | [`08-keeping-documents-current.md`](../../08-keeping-documents-current.md) |
| About to write a path or a measured number | [`durable-references`](../durable-references/SKILL.md) | [`09-durable-references.md`](../../09-durable-references.md) |
| Branch, worktree, base checkout, publish tip | [`repository-worktrees`](../repository-worktrees/SKILL.md) | [`10-repository-and-worktree-layout.md`](../../10-repository-and-worktree-layout.md) |
| About to trust a check's output | [`evidence-and-verification`](../evidence-and-verification/SKILL.md) | [`11-evidence-and-verification.md`](../../11-evidence-and-verification.md) |
| Copying a database or crossing a boundary | [`data-handling-boundaries`](../data-handling-boundaries/SKILL.md) | [`12-data-handling-and-boundaries.md`](../../12-data-handling-and-boundaries.md) |
| More than one agent, or a tasklist | [`concurrent-agents`](../concurrent-agents/SKILL.md) | [`13-concurrent-agents-and-working-memory.md`](../../13-concurrent-agents-and-working-memory.md) |
| Where an agent file should land | [`agent-file-placement`](../agent-file-placement/SKILL.md) | [`14-agent-working-directories-and-file-placement.md`](../../14-agent-working-directories-and-file-placement.md) |
| Work that will happen again | [`workflow-and-plan`](../workflow-and-plan/SKILL.md) | [`15-workflow-and-plan-pair.md`](../../15-workflow-and-plan-pair.md) |
| Writing a fact for a later session | [`working-memory`](../working-memory/SKILL.md) | [`16-working-memory-protocol.md`](../../16-working-memory-protocol.md) |
| Publish, or a deploy tree that looks like source | [`deploy-artifacts`](../deploy-artifacts/SKILL.md) | [`18-deploy-artifacts-are-not-source.md`](../../18-deploy-artifacts-are-not-source.md) |

One skill per standards file outside `standards/skills/`. If a file there has no row,
this router is wrong — add the row upstream in the same change that added the file.

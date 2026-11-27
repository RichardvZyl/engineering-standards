---
name: repo-layout
description: >
  Place files in a repository checkout and name projects. Use when adding a directory, a project, a docs path, or an AGENTS.md. The root holds configuration, not content. Triggers: folder structure, src, tests, namespace, AGENTS.md, project name, Common, Utils.
metadata:
  standard: standards/07-repo-layout.md
---

<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# Repository layout

The rule is [`07-repo-layout.md`](../../07-repo-layout.md). Read that file before you act. This skill is the
trigger and the order of work. If a line here and the standard disagree, the standard
wins — fix this skill upstream in the same change. Do not grow a second copy of the rule.

## When

Adding or moving a directory, project, or the repository instruction file.

## Also load

- [`documentation-layout`](../documentation-layout/SKILL.md)
- [`agent-file-placement`](../agent-file-placement/SKILL.md)

Load those only when their descriptions match the task. Do not load the rest of the set.

## Apply, in this order

1. The shape in the standard describes the checkout, not a deploy tree. The root holds configuration, not content.
2. src/ and tests/ mirror one another. Documentation lives in docs/, with the exceptions the standard names. docs/planning/ holds run artifacts, not agent state. standards/ is vendored and read-only.
3. Directories are lowercase and hyphenated, except where a .NET project directory matches its project name. A name says what the thing is. Common, Shared, Utils, and Helpers are prohibited as project or namespace names.
4. AGENTS.md holds what is true of this project only, plus the path-to-domain-doc routing table, the working conventions an agent must know before starting, and the sole exception authorizer. A line that names a repo, org, client, or product does not belong in standards/. If those conventions are missing, stop and follow Conventions first.

## Do not

- A new Helpers or Shared project.
- Editing standards/ in a consuming repository.

## Done when

- [ ] A newcomer can see the shape of the system from the root, not a pile of files.

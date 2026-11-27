---
name: data-handling-boundaries
description: >
  Move data across process, filesystem, and interop boundaries without corrupting it. Use when copying a database, crossing a platform boundary, setting line endings, fixing ownership, or placing a secret near an agent-visible tree. Triggers: copy database, SQLite, line ending, CRLF, sandbox, secret file, interop, ownership.
metadata:
  standard: standards/12-data-handling-and-boundaries.md
---

<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# Data handling and boundaries

The rule is [`12-data-handling-and-boundaries.md`](../../12-data-handling-and-boundaries.md). Read that file before you act. This skill is the
trigger and the order of work. If a line here and the standard disagree, the standard
wins — fix this skill upstream in the same change. Do not grow a second copy of the rule.

## When

Copying or opening a database, crossing an interop boundary, or deciding where a secret file may sit.

## Also load

- [`durable-references`](../durable-references/SKILL.md)
- [`engineering-hygiene`](../engineering-hygiene/SKILL.md)

Load those only when their descriptions match the task. Do not load the rest of the set.

## Apply, in this order

1. Never copy a database a process may hold open.
2. Do not access a database across an interop boundary. Cross the boundary with a file or an API, not with a live database handle.
3. Pin line-ending policy in the repository. Do not rely on the client's configuration.
4. A clean status can be a property of the platform you asked, not of the tree. Confirm which tree you measured.
5. Fix ownership rather than disabling the ownership check.
6. Secrets must not sit inside a tree exposed as an agent sandbox root.
7. Run the review checklist in section 12.7.

## Do not

- Copying a live database file because the copy command succeeded.
- Turning off a safe-directory or ownership check to make a command pass.

## Done when

- [ ] The data crossed the boundary in a form the standard allows, and no secret landed in a sandbox root.

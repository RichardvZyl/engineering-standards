---
name: agent-file-placement
description: >
  Decide where an agent puts a file. Use when creating a working directory, a keepable document, or scratch output. Locations are relative to the configured development root, never a written absolute path. Triggers: where to put, scratch, temp, documents, symlink, agent directory, output file.
metadata:
  standard: standards/14-agent-working-directories-and-file-placement.md
---

<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# Agent file placement

The rule is [`14-agent-working-directories-and-file-placement.md`](../../14-agent-working-directories-and-file-placement.md). Read that file before you act. This skill is the
trigger and the order of work. If a line here and the standard disagree, the standard
wins — fix this skill upstream in the same change. Do not grow a second copy of the rule.

## When

About to create a file that is not the product change itself.

## Also load

- [`concurrent-agents`](../concurrent-agents/SKILL.md)
- [`durable-references`](../durable-references/SKILL.md)
- [`deploy-artifacts`](../deploy-artifacts/SKILL.md)

Load those only when their descriptions match the task. Do not load the rest of the set.

## Apply, in this order

1. Express every location relative to the configured development root. Do not write that root's concrete path into a document.
2. Per-provider working directories are symlinks into agents/. Do not scatter files across provider folders that nobody can inventory.
3. Files worth keeping go in the active worktree's documents folder. At a repository root with no worktrees, keepables go to the development root's documents folder.
4. Scratch goes to .temp under the development root and is deleted when finished.
5. Decide keepable versus scratch using section 14.5 before you write. A deploy tree is not a working directory.

## Do not

- Leaving scratch in the worktree because deleting it later feels risky. Deletion of scratch follows engineering-hygiene: recoverable, and only when it is actually scratch.
- A new per-provider directory that is not a link into agents/.

## Done when

- [ ] The checklist in section 14.6 is true: keepables and scratch are in the places the standard names, and no absolute path was written down.

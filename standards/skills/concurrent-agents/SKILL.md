---
name: concurrent-agents
description: >
  Keep concurrent agents from writing the same file. Use when more than one agent shares a tree, when writing working memory, or when keeping a running tasklist. Make conflict structurally impossible rather than merging it later. Triggers: concurrent, multi-agent, lock, append, tasklist, working memory file, writer.
metadata:
  standard: standards/13-concurrent-agents-and-working-memory.md
---

<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# Concurrent agents

The rule is [`13-concurrent-agents-and-working-memory.md`](../../13-concurrent-agents-and-working-memory.md). Read that file before you act. This skill is the
trigger and the order of work. If a line here and the standard disagree, the standard
wins — fix this skill upstream in the same change. Do not grow a second copy of the rule.

## When

More than one agent can touch the tree, or you are about to write in-flight state.

## Also load

- [`working-memory`](../working-memory/SKILL.md)
- [`agent-file-placement`](../agent-file-placement/SKILL.md)

Load those only when their descriptions match the task. Do not load the rest of the set.

## Apply, in this order

1. Exactly one writer per working-memory file. No agent writes another agent's file. The filename carries agent identity and an orchestrator-issued nonce, not a timestamp. Everyone may read.
2. Write the whole file: temporary file in the same directory, then rename into place. Never append. Never write the target in place.
3. When a finding changes the remaining work, update your own file before continuing. Retract the wrong statement; do not leave it standing.
4. A snapshot is not working memory. Do not treat a rendered context or a task board as the thing you amend.
5. Respect the cross-platform constraints on the working-memory directory in section 13.5.
6. For work larger than one prompt, keep a single tasklist and update it in place as each step completes, per section 13.6.

## Do not

- A shared file with an advisory lock as the coordination mechanism.
- Appending a status line to a file another agent, or a reader, may be scanning.

## Done when

- [ ] The checklist in section 13.7 holds: one writer, whole-file replacement, your own file updated if the plan changed.

---
name: working-memory
description: >
  Choose which memory surface a fact belongs on. Use when writing context, an initiative file, or durable shared memory. Three questions, in order; the first yes decides. A snapshot is not working memory. Triggers: memory, context file, initiative, durable, tier, remember, working file, transcript.
metadata:
  standard: standards/16-working-memory-protocol.md
---

<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# Working memory

The rule is [`16-working-memory-protocol.md`](../../16-working-memory-protocol.md). Read that file before you act. This skill is the
trigger and the order of work. If a line here and the standard disagree, the standard
wins — fix this skill upstream in the same change. Do not grow a second copy of the rule.

## When

About to write a fact down so a later session can use it.

## Also load

- [`concurrent-agents`](../concurrent-agents/SKILL.md)
- [`agent-file-placement`](../agent-file-placement/SKILL.md)
- [`durable-references`](../durable-references/SKILL.md)

Load those only when their descriptions match the task. Do not load the rest of the set.

## Apply, in this order

1. A snapshot is not working memory. The rendered context file is a read view. Do not write it. Surface agent state by naming the directory that holds it, not by restating the list.
2. Place the fact with three questions, in order, and stop at the first yes. Still true in another repository months from now: durable shared memory. In-flight work that touches more than one repository: the initiative file. Otherwise: per-project context.
3. Apply the tie-breakers in 16.2.1. A durable convention found during cross-repo work is durable shared memory. An initiative's own progress stays on the initiative. A fact about one repository stays on that repository even if a wide effort found it. One repository's long task is not cross-repo.
4. Never store secrets, session transcripts, volatile numbers as durable fact, or an unverified claim stated as verified.
5. Each agent writes exactly one working file plus its matching completed drain file. Writes are rename-into-place. The file accumulates across prompts and drains; it is not reset per prompt.
6. Update your own file when a finding changes the remaining work, not only at a prompt boundary.
7. Remote reachability of these surfaces is an access-control decision: scope the root, require authentication, record the choice in project context or an ADR. Do not ship one estate's scope as a downstream default.

## Do not

- Writing in-flight tasks into durable shared memory because they feel important.
- Restating a working-file list into the rendered context.

## Done when

- [ ] The checklist in section 16.12 holds, including which of the three questions fired and that no secret or transcript was stored.

---
name: evidence-and-verification
description: >
  Decide what counts as proof before relying on it. Use when a check passed, a path is absent, a port bound, a page omitted a row, or a snapshot claims to be current. Triggers: verify, proof, backup, missing file, rename, bind, health check, dry-run, snapshot.
metadata:
  standard: standards/11-evidence-and-verification.md
---

<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# Evidence and verification

The rule is [`11-evidence-and-verification.md`](../../11-evidence-and-verification.md). Read that file before you act. This skill is the
trigger and the order of work. If a line here and the standard disagree, the standard
wins — fix this skill upstream in the same change. Do not grow a second copy of the rule.

## When

You are about to treat a command's output as evidence that something is true.

## Also load

- [`durable-references`](../durable-references/SKILL.md)

Load those only when their descriptions match the task. Do not load the rest of the set.

## Apply, in this order

1. Verify a backup with the correct harness before relying on it.
2. Path-level absence proves nothing when a rename may be in play. Establish the rename before concluding the thing is gone.
3. Do not infer a subsystem's state from an adjacent line of output.
4. Dry-run a vendor wiring command and read the destination it prints before running it.
5. A snapshot is never a source of truth.
6. A successful bind is not proof of reachability.
7. Absence from a page is not absence.
8. Walk the review checklist in section 11.8 and record the check, not a volatile measurement, in durable text.

## Do not

- Declaring a file lost because the old path 404s.
- Treating a listening socket as proof a client can complete the operation.

## Done when

- [ ] The claim you are about to write names the harness that produced it, and that harness is the one that can actually see the failure.

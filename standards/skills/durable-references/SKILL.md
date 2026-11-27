---
name: durable-references
description: >
  Stop absolute paths and volatile numbers from being written into durable text. Use when writing docs, ADRs, AGENTS.md, config, scripts, commit messages, examples, or memory. Triggers: absolute path, drive letter, home directory, count, hash, byte size, timing, file count.
metadata:
  standard: standards/09-durable-references.md
---

<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# Durable references

The rule is [`09-durable-references.md`](../../09-durable-references.md). Read that file before you act. This skill is the
trigger and the order of work. If a line here and the standard disagree, the standard
wins — fix this skill upstream in the same change. Do not grow a second copy of the rule.

## When

About to write a location or a number into anything that outlives the session.

## Also load

- [`evidence-and-verification`](../evidence-and-verification/SKILL.md)

Load those only when their descriptions match the task. Do not load the rest of the set.

## Apply, in this order

1. Never write an absolute filesystem path. Use a repo-relative path, or a variable resolved at use time. A concrete runtime path is an input, not a literal. Examples obey this, because examples get copied.
2. Never write a number that is a measurement of current state. Record the check that regenerates it. Volatile: file, object, commit, row, table, page, and ref counts; sizes; hashes; timings. Structural: a configured port, a schema version, a policy limit.
3. Measurements belong in a dated run log. Durable text cites the log.
4. Run the review checklist in section 9.3 before committing the text.

## Do not

- A drive letter, a mount path, a home-directory path, or a per-user profile path in a document, script, or example.
- Inlining a count because you just measured it.

## Done when

- [ ] Every location in the change is relative or variable-resolved, and every number is structural or replaced by the check that produces it.

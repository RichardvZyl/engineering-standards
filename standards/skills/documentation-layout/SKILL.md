---
name: documentation-layout
description: >
  Place documents and cite planning identifiers. Use when adding a plan, backlog, roadmap, run artifact, or when mentioning an identifier in prose, a commit, or chat. Triggers: planning doc, identifier, backlog, roadmap, workstream, task id, gloss, docs folder.
metadata:
  standard: standards/04-documentation-layout.md
---

<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# Documentation layout

The rule is [`04-documentation-layout.md`](../../04-documentation-layout.md). Read that file before you act. This skill is the
trigger and the order of work. If a line here and the standard disagree, the standard
wins — fix this skill upstream in the same change. Do not grow a second copy of the rule.

## When

Creating or moving a document, or citing an identifier.

## Also load

- [`response-and-collaboration`](../response-and-collaboration/SKILL.md)
- [`keeping-documents-current`](../keeping-documents-current/SKILL.md)

Load those only when their descriptions match the task. Do not load the rest of the set.

## Apply, in this order

1. A planning document owns the items it defines: it assigns their identifiers and is where they are looked up. Planning documents live in docs/. Run artifacts live under docs/planning/, not in an agent-state directory.
2. Every planning item has exactly one identifier, assigned by the owning document. Form is an optional group, a category the document defines, and an ordinal unique within that category.
3. On every mention, precede the identifier with its fully qualified category name and follow it with a one-line claim gloss. The gloss is the claim, not a restatement of the category.
4. An identifier is permanent. Never reuse it, never renumber it. Ordinals record insertion order, not priority. A downstream document cites the owner's identifier; it does not mint its own. If two schemes already exist, record the mapping. Do not silently pick one.
5. Status lives beside the item.

## Do not

- A bare identifier with no category name and no gloss.
- Agent state stored under docs/planning/.

## Done when

- [ ] A reader can resolve every identifier to the owning document without asking.

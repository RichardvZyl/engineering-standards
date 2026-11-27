---
name: deploy-artifacts
description: >
  Keep published runtime trees as release snapshots, not editable repositories. Use when publishing, when a deploy directory contains source or tests, or when an agent is about to edit a running tree. Triggers: deploy, publish, current junction, generated banner, BUILD.json, release bundle.
metadata:
  standard: standards/18-deploy-artifacts-are-not-source.md
---

<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# Deploy artifacts are not source

The rule is [`18-deploy-artifacts-are-not-source.md`](../../18-deploy-artifacts-are-not-source.md). Read that file before you act. This skill is the
trigger and the order of work. If a line here and the standard disagree, the standard
wins — fix this skill upstream in the same change. Do not grow a second copy of the rule.

## When

Publishing a service, or finding source-shaped files in a deploy tree.

## Also load

- [`repository-worktrees`](../repository-worktrees/SKILL.md)
- [`evidence-and-verification`](../evidence-and-verification/SKILL.md)

Load those only when their descriptions match the task. Do not load the rest of the set.

## Apply, in this order

1. Do not edit a deploy tree. Canonical source is the repository on its integration tip. What runs is a built bundle.
2. A published tree must not look like source: no project layout an agent could mistake for the repository. Prefer content-addressed release directories plus a current pointer.
3. Every shipped code artifact begins with a generated, do-not-edit banner carrying the source repository identity and the commit it was built from. The launcher refuses to start if the banner is missing or a sibling source file is present.
4. After publish, code artifacts are read-only so an in-place edit fails loudly.
5. Editable ops inputs live outside the immutable code bundle. Code changes are rebuild and republish, never a patch to the running tree.
6. Every publish writes BUILD.json with the identity the standard requires, and a health or status endpoint can echo it. There is one publish path: build from the integration tip, minify, write the content-addressed folder, then flip current. Do not copy raw sources as the runnable tree.

## Do not

- Opening the current deploy directory in an editor because it contains a familiar entry file.
- A second, hand-run publish path that copies the working tree.

## Done when

- [ ] The checklist in section 18.7 holds for the tree you just published or refused to edit.

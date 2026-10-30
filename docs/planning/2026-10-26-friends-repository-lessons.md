---
title: Make three lessons from a friend's repository executable in the standards set
created: 2026-10-26
repo: engineering-standards
head: 2a73616
status: draft
---

# Make three lessons from a friend's repository executable in the standards set

## Goal

A consuming repository fails its build when a canonical document drifts, and its verification command is chosen from the diff and leaves the tree unchanged. The standards set states those rules, and this repository's own scripts demonstrate the part that applies to itself. No policy pack from a friend's repository is copied in.

## Grounding

What was verified before planning. Standards text is from the checkout that matches merged `origin/main` at `2a73616`.

| Fact | Evidence |
|---|---|
| Trunk is `main` at `2a73616`, `standards/VERSION` `0.8.0`. The layout correction is already merged. | `origin/main`; pull request #18 |
| A convention the build does not enforce erodes. Formatting, analyzers, tests, coverage, and secret scanning are the machine's job. | `standards/03-engineering-hygiene.md:19`; `standards/06-review-standards.md:12` |
| Restating a version or roster rots because nothing fails. The prescribed fix is a pointer to the single source. | `standards/08-keeping-documents-current.md:60-74` |
| Review stays on two unmerged axes: standards, and the plan item's acceptance. | `standards/06-review-standards.md:19-34` |
| This repository already fails the build on a missing vendoring header, an invalid `standards/VERSION`, a broken relative link under `standards/`, and an ADR index mismatch. Templates are excluded because their links resolve only after seeding. | `scripts/Test-StandardsIntegrity.ps1:8-20` |
| A standards change that does not bump `standards/VERSION` fails `verify-standards`. | Workflow step observed on pull request #18 before `09c966b` |
| The seeded agent file already routes by directory, and it already has a "Running it" placeholder. It does not route by task, and it does not say that a restated toolchain version is a defect. | `templates/AGENTS.md.template:33-43`, `:84-88` |
| A plan owns its identifiers and keeps status beside the item. A workflow must not reference a plan. | `standards/04-documentation-layout.md:12-68`; `standards/15-workflow-and-plan-pair.md:14-16` |
| A friend's repository selects one verification gate from the changed paths, prints a single `PASS` line, and fails a CI phase that dirties the tree. | a friend's repository: its verification command and its change-validation document |
| A friend's repository fails documentation when the index and the route manifest disagree, a relative link or script name does not resolve, or the README, pin file, and workflow name different toolchain versions. | a friend's repository: its documentation policy |
| The Rust, React, and Tauri policy pack in a friend's repository is specific to that codebase. Its checkout is the repository directory, which this standards set rejects. Its generated build output was untracked rather than ignored. | a friend's repository; `standards/10-repository-and-worktree-layout.md:59-65` |

**Already satisfied — dropped from the plan:**

- Copying the formatter, import, logging, or architecture validators from a friend's repository. Standard 03 already says the build enforces style, and standard 06 already says review is for what the build cannot see.
- Switching line endings to LF. The shipped `.editorconfig` is CRLF for the .NET set (`standards/03-engineering-hygiene.md:16-17`).
- Adopting the repository layout from a friend's repository. Standard 10 already requires `root/` plus sibling worktrees.
- A separate run-guide standard. The template already has "Running it". The missing rule is "point at the pin", which standard 08 already states.
- Splitting the development-root `AGENTS.md`. That file is an instance. This repository must not name it (`engineering-standards` `AGENTS.md`, "the template carries the convention, never the instance").

**Constraints:** `standards/` is vendored and read-only downstream. A new requirement is a minor bump (`0.8.0` → `0.9.0`) with its own dated changelog block. No repo, org, client, product, or machine path in `standards/`. Execute from a worktree of `origin/main`, not from a dirty base checkout.

## Steps

```yaml
- id: S1
  title: State in standard 08 that canonical-doc drift fails the build
  status: pending
  files:
    - standards/08-keeping-documents-current.md
  dependsOn: []
  acceptance: Standard 08 says a repository fails its build when a canonical document's relative link, cited command, or toolchain pin disagrees with the single source. The prose names no product and no implementation language.
  rollback: Revert the standard 08 edit.
  checkpoint: true

- id: S2
  title: State in standard 03 how verification is selected and that it must not dirty the tree
  status: pending
  files:
    - standards/03-engineering-hygiene.md
  dependsOn: []
  acceptance: Standard 03 requires one command that chooses the narrowest gate from the changed paths, reports success as a single line, and fails when the command changes the worktree. Focused iteration stays allowed before that final command.
  rollback: Revert the standard 03 edit.
  checkpoint: false

- id: S3
  title: Point the seeded agent file at task routes and at pin files
  status: pending
  files:
    - templates/AGENTS.md.template
  dependsOn: [S1]
  acceptance: The template has a task-route table (work type to the smallest set of documents) in addition to the existing directory table. "Running it" says to name commands and to point at the pin file rather than restate its version. Placeholders stay placeholders.
  rollback: Revert the template edit.
  checkpoint: false

- id: S4
  title: Require a plan that implements a specification to name that specification
  status: pending
  files:
    - standards/04-documentation-layout.md
  dependsOn: []
  acceptance: Standard 04 says an implementation plan names the canonical specification it implements. Standard 15 is unchanged; the workflow still must not reference the plan.
  rollback: Revert the standard 04 edit.
  checkpoint: false

- id: S5
  title: Cut 0.9.0 and prove the standards repo still verifies
  status: pending
  files:
    - standards/VERSION
    - CHANGELOG.md
  dependsOn: [S1, S2, S4, S6]
  acceptance: standards/VERSION is 0.9.0. CHANGELOG has a dated 0.9.0 block and an empty Unreleased section. pwsh ./scripts/Test-NoProprietaryLeak.ps1 and pwsh ./scripts/Test-StandardsIntegrity.ps1 both exit 0, with S6's check included. The verify-standards workflow is green on the pull request.
  rollback: Revert the version and changelog commit.
  checkpoint: true

- id: S6
  title: Make the integrity script fail on the drift surfaces this repository has
  status: pending
  files:
    - scripts/Test-StandardsIntegrity.ps1
  dependsOn: [S1]
  acceptance: Test-StandardsIntegrity.ps1 gains a numbered check, listed in its .DESCRIPTION, that fails when a script path cited in this repository's markdown outside templates/ does not resolve. A temporary broken citation makes the script exit 1, and removing it restores exit 0. No pin-file check is added, because this repository has no pin file. The existing relative-link and VERSION checks are unchanged.
  rollback: Revert the script edit.
  checkpoint: false
```

## Order

```
S1 ──→ S6 ─┐
S2 ────────┼→ S5
S4 ────────┘
S3 ──→ (after S1, no version dependency beyond being in the same pull request)

checkpoints: after S1 (the new requirement is the contract), after S5 (version and both local scripts, including S6's check)
```

S3 is seeded once and is not under `standards/`, so it does not by itself force the version bump. It still belongs in the same pull request so the template and the rule ship together.

## Verification

- **Per checkpoint:** After S1, re-read standard 08 against `scripts/Test-StandardsIntegrity.ps1` and confirm the new sentence does not claim a check this repository does not have, unless S6 added that check. After S5, both PowerShell scripts exit 0.
- **End to end:** A pull request into `main` changes only the files listed above. `verify-standards` is green. A reader can point at standard 08 for "drift fails" and standard 03 for "the gate is selected from the diff".
- **Regression risk:** The vendoring header and the leak guard. Integrity already scans every `standards/**` markdown link. A new internal link that does not resolve fails S5.

## Open questions

> Breadth is the deliverable here. No approval while a question its steps depend on is `open` — decide it, or mark `deferred` with why that is safe.

### Q1 — Where does "drift fails the build" live?

- **Affects:** S1, S5
- **Status:** recommended: extend standard 08
- **Options:**

  | Option | Upside | Downside | Cost to reverse later |
  |---|---|---|---|
  | A — Extend 08 | The gap is already named there, at lines 64-66. One owner. | 08 gets longer. | Revert the section. Low. |
  | B — New standard 17 | A short standard, easy to cite. | 17 was drafted in the lockdown handoff for a different rule. A second home for currency. | Renumber or leave a retired 17. Higher. |
  | C — Do nothing | No new requirement to vend. | The sentence "nothing fails when it goes wrong" stays a description of the defect. | Adopting it later is the same work as A. |

- **Plan impact per option:** A keeps S1. B replaces S1's file with `standards/17-*.md` and adds an index row wherever standards are listed. C drops S1, S3's pin sentence, and the minor bump; S2 can still ship as a patch.
- **Nuances / edge cases that bite here:** The standards repo has no toolchain pin file of its own. The rule must be written so a repository without a pin file is not in breach. Templates stay excluded from link checking, because their links are meant to resolve after seeding.
- **If we choose wrong:** A new 17 collides with the handoff draft and splits currency across 08 and 17. Doing nothing leaves consuming repos free to restate versions. You find out on the next sync, when a README and a workflow disagree and the build stays green.
- **Recommendation:** A. Standard 08 already owns the defect.

### Q2 — Does this repository grow a new checker, or only the rule?

- **Affects:** S1, S5, S6
- **Status:** recommended: rule in the standard, extend the existing script only for surfaces this repository has
- **Options:**

  | Option | Upside | Downside | Cost to reverse later |
  |---|---|---|---|
  | A — Rule plus the checks this repo can actually run | Matches "where the build can enforce a rule, it does." Links already fail. VERSION already fails. | A .NET repo must write its own check. The standard does not ship them a script. | Delete the extra assertions. Low. |
  | B — Ship a language-neutral validator in this repo for downstream to call | One implementation. | This repo would grow a tool it does not need, and downstream would take a dependency on it. Violates "prefer the platform". | Removing a consumed script is a breaking change. High. |
  | C — Prose only, no new assertion here | Smallest diff. | Standard 03 says a document-only convention erodes. This repo would state a rule it does not keep. | Adding the assertion later is easy. The credibility cost is paid until then. |

- **Plan impact per option:** A keeps S6 as the script assertion and S5 as script-green plus a changelog. B replaces S6 with a `scripts/` tool and a template snippet, and likely pushes the bump to `0.9.0` still, but the blast radius includes every future consumer. C drops S6.
- **Nuances / edge cases that bite here:** `Test-StandardsIntegrity.ps1` already checks relative links under `standards/` and skips `templates/`. Do not "fix" template links. Do not require a Rust or Node pin in a repository that has neither.
- **If we choose wrong:** B couples every consuming repo to this repo's script layout. C makes the new paragraph an example of the defect it describes. You find out when the next standards edit restates a version and CI stays green.
- **Recommendation:** A. The reference implementation is the script this repo already runs.

### Q3 — Require a plan to name its canonical specification?

- **Affects:** S4
- **Status:** recommended: yes, one sentence in standard 04
- **Options:**

  | Option | Upside | Downside | Cost to reverse later |
  |---|---|---|---|
  | A — One sentence in standard 04 | Closes the hole a friend's repository closes with plan metadata. Status and identifier rules stay put. | Some notes that are not implementation plans will be misread as in breach. | Revert the sentence. Low. |
  | B — Put it in standard 15 | Sits next to the one-way dependency. | 15 is about workflows and plans as a pair, not about specifications. Two owners for "what a plan contains". | Revert. Low, but the mis-filing remains until someone notices. |
  | C — Defer | Smaller 0.9.0. | Agents keep treating a finished plan as the spec. Standard 06 already says acceptance lives on the item; it does not say the item must name the spec. | Adding the sentence later is the same work. |

- **Plan impact per option:** A keeps S4. B moves S4's file to standard 15. C drops S4. S5 still happens if S1 or S2 landed.
- **Nuances / edge cases that bite here:** A spike, a checklist, and a run log are not implementation plans. The sentence has to say which documents owe the link. Standard 15's rule must stay one-way.
- **If we choose wrong:** B trains readers to look in 15 for a documentation-layout rule. C leaves the failure a friend's repository hit: setup and behaviour get inferred from a stale plan. You find out when two documents disagree and the plan is the one an agent loaded.
- **Recommendation:** A. Scope it to implementation plans, not to every note.

### Q4 — Word budgets and duplicate-paragraph checks?

- **Affects:** none of S1–S6 unless this is promoted
- **Status:** deferred. Safe because standards 06 and 08 already forbid a second copy of a rule, and a 25-word detector false-positives on repeated legal text.
- **Options:**

  | Option | Upside | Downside | Cost to reverse later |
  |---|---|---|---|
  | A — Adopt the budgets and duplicate detector from a friend's repository | Agent context stops growing without a tripwire. | The numbers come from a friend's repository and are tuned to that docs set. False positives become suppressions. | Removing a required check is a behaviour change for consumers. Medium. |
  | B — Defer | The 0.9.0 rule stays about links, commands, and pins. | Long agent files keep growing until a reader notices. | Adding it later is a further minor bump. |

- **Plan impact per option:** A adds a step before S5 and a new script assertion. B changes nothing in the steps above.
- **Nuances / edge cases that bite here:** A threshold that drives behaviour is allowed by standard 08. A threshold copied from another repository is a census of that repository. The vendored header is repeated on every standard and must not count as duplicate prose.
- **If we choose wrong:** A makes `verify-standards` fail on the header or on a deliberate repeated definition. You find out on the first push of 0.9.0.
- **Recommendation:** B. Revisit when a consuming repo shows the rot standard 08 describes and the pointer rule was not enough.

### Q5 — Is 0.9.0 the right bump?

- **Affects:** S5
- **Status:** recommended: minor `0.9.0`, if S1 or S2 is accepted
- **Options:**

  | Option | Upside | Downside | Cost to reverse later |
  |---|---|---|---|
  | A — Minor 0.9.0 | Matches the changelog scale: a rule is added. Downstream sees a sync PR. | Consumers who were silent on docs drift become non-compliant on the next sync. | Yanking a version is worse than shipping the next one. |
  | B — Patch 0.8.1 | Quieter. | A new failure mode is not "wording, links, typos". Mis-classifies the change. | Re-releasing as 0.9.0 confuses the sync history. |
  | C — Hold the bump until a consumer exists | No sync noise. | The verify workflow fails a standards change with no VERSION bump. The rule would be invisible downstream, which is the defect 08 describes. | Cutting 0.9.0 later is the same work. |

- **Plan impact per option:** A is S5 as written. B changes only the number. C cannot be done: the workflow rejects a `standards/` edit that leaves `VERSION` alone.
- **Nuances / edge cases that bite here:** Sync PR titles are built from `standards/VERSION`. An empty Unreleased section must remain above the new dated block.
- **If we choose wrong:** B teaches the next editor that a new gate is a patch. You find out when a later major reversal is also filed as a patch and downstream misses it.
- **Recommendation:** A.

## Risks

- The new standard 08 sentence gets written as if every repository had the Node validator from a friend's repository. Early warning: the draft names a script, a framework, or a file this repository does not have.
- S3's task-route table becomes a second copy of standards 00–16. Early warning: the template lists rules instead of document paths.
- Executing this plan in a dirty base checkout would mix the version bump with unrelated edits. Use a new worktree from `origin/main`.

---
**Approve, edit any step, or answer the open questions first.**
Escalate to `/orchestration-1-plan` if this grew past ~8 independent steps or mixed model tiers.

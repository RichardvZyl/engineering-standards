# HANDOFF — machine lockdown, 2026-10-16

Written on instruction to stop mid-flight before this PC and the development tree are locked down for
a move to a server. Pointers, not contents. Everything stated here was verified unless it says
otherwise; where there is no evidence, it says "no record" rather than guessing.

---

## 1. THE HIGHEST-VALUE SECTION: work that does not survive a lockdown

### Committed but on NO remote — loses everything if the tree goes

| Repository | Branch | What is at risk |
|---|---|---|
| `engineering-standards` | `standards/09-through-15` | **3 commits past the merged PR #15**, on no remote ref. `5c0d6b2` (standards 16 and 11 — "absence from a page is not absence"), `642322f` (VERSION 0.8.0 → 0.7.0), `313b19f` (standard 16 generalisation). Its remote branch was deleted after PR #15 merged, so nothing points at these. |
| `Abstractions` | `feature/capabilities-abstractions` | commits on no remote ref (verified: remote-refs = 0) |
| `reusable ai tools` | `feat/skill-review` | **21 commits** on no remote ref. Largest uncaptured branch in the estate. |

An earlier sweep found **16 repositories holding local-only work**. Only the three above were
individually verified. **Assume the rest are unpushed until checked.**

### Uncommitted working-tree edits

| Repository | Path | State |
|---|---|---|
| `engineering-standards` | `root` worktree, branch `main` | 4 modified files: `AGENTS.md`, `CHANGELOG.md`, `standards/03-engineering-hygiene.md`, `standards/07-repo-layout.md`. Not inspected in detail. |

Also: local `main` in that worktree sits at `3c5dcff`, **one commit behind `origin/main` (`b24c51b`)**.
It is behind, not diverged — a fast-forward once the loose edits are dealt with.

### Not in git at all

`${dev-root}/documents/` is **not under version control** (verified). Everything in it is
machine-only, including two documents written today (see section 3).

Also flagged, not touched: `${dev-root}/documents/OpenAI API key free tier.txt` — filename asserts a
plaintext key on disk. Not opened. Should not travel to the server as-is.

---

## 2. What was in flight at the stop

### The three A2A deliverables — all three WRITTEN, none LANDED

All three exist as complete drafts in the session outputs folder only. **None was copied into the
development tree, none committed, none pushed.** They are in the session transcript if the outputs
folder is lost.

| # | Deliverable | State | Intended destination |
|---|---|---|---|
| 1 | A2A model-choice guide (`d1-model-choice.md`) | **written, complete** — Part 1 grounded findings, Part 2 the decision rule, Part 3 contingent + update trigger | `Projects/A2A Project folder/docs/` |
| 2a | Routing workflow (`d2-workflow.md`) | **written, complete** — generic, references no plan (standard 15) | `${dev-root}/documents/` |
| 2b | Routing recommendation (`d2-plan.md`) | **written, complete** — tiers 0/1/2, escalation trigger, cost asymmetries, misroute detection and recovery | `Projects/A2A Project folder/docs/` |
| 3 | Standard 17 (`17-standard.md`) | **written, complete** — "A timestamped observation is not present state" | `engineering-standards`, new branch |
| — | AGENTS.md section (`agents-section.md`) | **written, complete** | durable memory, place 2 |

**Stopped at:** landing step. The shell classifier began timing out and the prep script
(`a8-prep.ps1`, read-only: open-PR check, CHANGELOG format, index file, vault CLI syntax) never ran.
Nothing was committed, so nothing is half-committed.

**Not done for deliverable 3:** VERSION bump to 0.8.0, CHANGELOG block, standards index entry, and the
durable-memory writes (all three places). Standard 17 is drafted text and nothing more.

---

## 3. Items 1–6 of the previous brief

**Honest position first: that six-item brief is not in my available context** — it predates a context
compaction and I cannot re-read it. I am reporting only what I can evidence from this session. Treat
every "no record" below as **not started**.

| # | Item | State | Evidence |
|---|---|---|---|
| 1 | Two branch pushes and draft PRs | **Partial, and not as described.** Two worktrees were pruned (`pr49` → `feat/copilot-review-response-workflow`, `reorg` → `chore/project-specific-snapshots`), each behind two gates. **No new PRs were created** — both branches already had open PRs (#49, #51) at the exact head commit; a second PR per branch is impossible and downgrading an open PR to draft would disrupt review. So: pushes not needed, draft PRs not created, and the reason is recorded. |
| 2 | The retro | **No record.** | — |
| 3 | Orchestration System | **Not started.** Two of its worktrees (`mvp-capabilities-mcp-refactor`, `mvp-capabilities-mcp`) were examined and deliberately left alone — both inside the recency ambiguity band, both pointing at the same head `edafcd0d`, which is itself worth someone's attention. No other work done. |
| 4 | 16.4 and 13 amendments | **Partial — drafted, not landed.** The 16.4 contradiction with 13.1 was found and a proposed amendment written into `${dev-root}/.working-memory/worktree-consolidation/claude-opus-session--a96bbb502eaf.md`. Substance: 16.4 demands an orchestrator-issued nonce, but a single agent working alone has no orchestrator; proposed wording forbids timestamps while permitting self-issuance. **Never committed to the standards repo.** |
| 5 | Credential recommendation | **DONE and landed.** Two files written to `${dev-root}/documents/`: `workflow-credential-diagnosis-and-restore.md` and `plan-github-credential-state-2026-10-15.md`. Both passed encoding and leak gates. **Caveat: `documents/` is not under git**, so these are machine-only. |
| 6 | Ingest script | **No record.** | — |

---

## 4. The confirmed A2A findings — not written down anywhere else

**The node runs an alias, not a pinned model.** The A2A front door is `agentic_data_stack`, a Google
ADK for TypeScript `LlmAgent` (`@google/adk` 2.2.0) mounted with `toA2a` on loopback **8095**, at
`Agents, IDE's, Tools, Services/Development Tools/AgenticStack/agentic-data-stack/a2a`.

Its model is set at `a2a/src/agent.ts`:

```ts
export const GEMINI_MODEL = 'gemini-flash-latest';
```

`A2A_MODEL` and `A2A_LLM_BACKEND` can override it and **neither is set**. The key is read from
Credential Manager target `A2A/GOOGLE_GENAI_API_KEY` at startup and is present.

So **it is not Gemini 3 Flash and not Gemini 3 Flash Lite — there is no version pin at all.** What the
alias currently resolves to **could not be confirmed from this machine**: the metadata endpoint reports
`version: "Gemini Flash Latest"` (self-referential), and `generateContent`, which does report the
concrete `modelVersion`, returned HTTP 429 on three attempts. **To confirm: one successful
`generateContent` against `gemini-flash-latest`, read `modelVersion`.** Published behaviour: the alias
is hot-swapped per release, has already moved at least once, and an ADK issue records it 404-ing after
its target was retired. **Recommendation: pin it.**

**Live operational finding:** the Gemini key is 429-exhausted. The node wraps Gemini in
`GeminiWithAcknowledgedLocalFallback`, so it does **not** silently fall back — the task stays
`input-required` pending an `acknowledged=true` reply. **Under quota exhaustion the front door presents
as a hang, not an error.**

**`Buzz` already exists at the development root.** `${dev-root}/Buzz/` holds installed binaries dated
2026-10-09: `buzz.exe`, `buzz-agent.exe`, `buzz-acp.exe`, `buzz-dev-mcp.exe`, `buzz-desktop.exe`, plus
`git-credential-nostr.exe` and `identity.ncryptsec`. This is Buzz by Block — Apache 2.0, Nostr-based,
agents hold their own keypairs. `buzz-agent` is an ACP client, `buzz-acp` bridges to Claude Code /
Codex / goose. **It fronts the same CLIs rather than replacing them.** The `identity.ncryptsec` key
file is machine-local and should be accounted for in the move.

**Peer roster** (loopback): `cursor` 8102, `claude-haiku` 8103, `claude-sonnet` 8104, `claude-opus`
8105, `gemini-flash` 8106, `gemini-pro` 8107, `cline` 8108, `devin` 8109, `qwen` 8110 (opt-in, not
live), `grok` 8111, `agy` 8112, `hermes` 8113 (**advertised in the roster but served no card**),
`openclaw` 18789, plus a `claude` alias card on 8101 → sonnet. Per standard 17 this list is
as-of-observation; re-check live.

**Two findings worth carrying forward:** five coding peers (`cursor`, `cline`, `devin`, `grok`, `agy`)
have functionally interchangeable card descriptions, so the router's pick among them is close to
arbitrary — name one. And their real discriminator is permission posture, which nothing instructs the
router to weigh: **`cline` cannot edit files (plan mode), `agy` auto-denies approval-needing tools,
`devin` auto-approves read-only tools.**

**Switchyard / one-silo:** NVIDIA NeMo Switchyard verified as a real open-source Apache 2.0 routing
proxy. **"Bundled with buz" could not be verified** — no source links them; the vendoring precedent is
with NVIDIA's own NeMo Platform. **"one-silo" could not be identified at all** under that name.

---

## 5. Open decisions awaiting the user

1. **`Abstractions` has zero open PRs, not six.** The brief that said six was stale. Whether to open a
   PR for `feature/capabilities-abstractions` is now an open question, not a thing to avoid.
2. **Two branches hold commits on no remote** (section 1) — both were judged in progress and left
   alone. They need a decision: push, or accept the risk.
3. **`reusable ai tools`** had 71 working-tree entries including 39 staged renames needing a design
   decision. Not revisited since.
4. **The `1mcp.env` cleanup** — its four values are English scrub notices, not secrets and not
   machine-readable pointers; the aggregator never reads the file. Recommended: blank the values,
   keep a header comment. Not done.
5. **Aggregator token scope** — the Credential Manager GitHub token carries 14 scopes including
   `admin:repo_hook`, `audit_log`, `write:packages`. Nothing observed needs more than `repo`,
   `read:org`, `workflow`. Narrowing it is a rotation; steps are in the credential workflow document.
6. **Standard 17 numbering** assumes 09–16 on `origin/main`, which was verified. Confirm before
   landing.

## 6. Standards drafted but not applied

- **Standard 17** — drafted in full, not committed. Needs VERSION 0.7.0 → 0.8.0, its own CHANGELOG
  block (never folded into another version's block), and an index entry.
- **16.4 amendment** — drafted in the working-memory file, not committed.
- **Durable memory** — the AGENTS.md section is drafted; **none of the three places was written.**

---

## 7. First five things for whoever resumes

1. Recover the three A2A deliverables from the session transcript and land them.
2. Push `standards/09-through-15`, `feature/capabilities-abstractions`, `feat/skill-review`.
3. Sweep the remaining repositories for unpushed branches — assume unpushed until verified.
4. Get `${dev-root}/documents/` under version control, or copy it somewhere that is.
5. Pin the A2A model and confirm what `gemini-flash-latest` resolved to.

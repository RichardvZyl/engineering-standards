<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# 16 — Working memory: three surfaces, one boundary rule

What an agent writes down while it works, where each fact goes, and why the obvious designs fail.

Locations are relative to `${dev-root}`, the single configured development root, per standards 09 and 14.

## 16.1 The spine: a snapshot is not working memory

Every failed design here failed the same way. Something was **materialised once and never
re-derived**, then read later as if it were still true.

- The rendered context file is overwritten wholesale on every prompt submission. Anything an agent
  wrote into it is gone, and anything it says about in-flight work is as old as the last render.
- The `@agora` task board shows the items that existed when work was *scoped*. When a finding causes
  a detour, the board does not move. **Recorded as failed, not as qualified** — it was tried and it
  misled.

Working memory has to be **the thing that is amended**, not a picture of it. Every other rule in this
standard is a consequence:

| Consequence | Because |
|---|---|
| Read view and write path are different files (16.3) | A file the renderer overwrites cannot hold state |
| One writer per file (16.4) | A merge step is a re-materialisation, and loses updates |
| Surfaced by pointer, never by restating (16.3) | A restated list is a second copy that goes stale |
| The detour rule (16.6) | An item that is no longer true must change *when* it stops being true |

## 16.2 The boundary rule

**Three questions, in order. The first "yes" decides the surface. Stop there.**

> **1. Would this still be true, and still worth knowing, in a different repository six months
>    from now?** → **Tier 3, the vault.** Durable shared memory.
>
> **2. Does this describe work that is in flight right now, and does that work touch more than one
>    repository?** → **Tier 2, the initiative file.** Cross-repo work in process.
>
> **3. Otherwise** → **Tier 1, per-project context.** Scoped to one repository.

Three properties make it usable. It is **ordered**, so two agents reach the same answer. It is
**total**, so there is no fact with nowhere to go. And each question is about the **fact**, not about
who is asking — the same fact lands in the same place regardless of which agent found it.

### 16.2.1 The tie-breakers that actually come up

- **A durable convention discovered during cross-repo work** → tier 3. Question 1 fires first, and it
  fires on purpose: the finding outlives the initiative that produced it. Leaving it in tier 2 means
  it dies when the initiative closes.
- **An initiative's own decisions and progress** → tier 2, even though they feel durable. They are
  *about* work in flight. When the initiative closes, the **generalisable lesson** is promoted to
  tier 3 and the rest is archived. That promotion is a deliberate step, not a side effect.
- **A repository-specific fact found while doing cross-repo work** → tier 1, that repository's
  context. Question 2 asks whether *the work* spans repositories; question 3 asks where the *fact*
  belongs. A fact about one repository belongs with that repository even when a wide initiative found
  it.
- **A single repository's multi-prompt task** → tier 1, not tier 2. Tier 2 earns its existence from
  *cross-repo* scope. One repository with a long task is still one repository.
- **Which agent is doing what, right now** → the agent's own working file (16.4). That is not a tier;
  it is the write path that feeds tiers 1 and 2.

### 16.2.2 What must never go in any of them

- **Secrets, credentials, tokens, keys.** Not in a context file, not in an initiative file, not in
  the vault. Where a secret is needed, an indirection names it and the value is resolved at use time
  (standards 09, 12).
- **Session transcripts.** Working memory is the standing state, not the conversation.
- **Volatile numbers presented as durable fact** — counts, sizes, hashes, timings. Record the check
  that regenerates them (standard 09). A measurement belongs in a dated run log.
- **Anything an agent has not verified**, stated as if verified. An unverified claim is labelled as
  such or omitted.

## 16.3 The read view versus the write path

**The rendered context file is a read view. Agents never write it.** The renderer overwrites it
wholesale on every prompt submission, so a write there is lost by construction — and worse, lost
*silently*, which is the failure mode standard 11 exists to prevent.

The render surfaces agent state by **naming the directory that holds it**, not by restating its
contents:

```text
## Working memory
Live agent working files: ${dev-root}/.working-memory/<initiative>/
Read them directly. This render does not reproduce their contents, deliberately:
a restated list is a second copy and goes stale the moment its owner amends the first.
```

A pointer cannot go stale in the way a copy can. The directory is either there or it is not, and what
is in it is whatever its owners last wrote.

## 16.4 Single writer per file

**Each agent owns exactly one working file and writes only that file.** Standard 13 owns the
mechanism; this section states what it means for these three surfaces and defers to 13 on the
details rather than restating them.

```text
${dev-root}/.working-memory/<initiative>/<agent-identity>--<session-id>.md
```

**The session identifier is an orchestrator-issued nonce, not a timestamp** (13.1). Two sessions
for the same agent launched in the same instant would select the same name from a timestamp, which
is precisely the collision single ownership exists to prevent. The agent does not invent this
identifier; it is issued to it.

**Writes go to a temporary file in the same directory and are renamed into place** (13.2). Never
appended, never written in place. Rename is the operation that carries the guarantee — a reader
sees the old content or the new one, never a mixture — and it holds only within one filesystem,
which is why the temporary never crosses a boundary.

**Read freely, write only your own.** An agent reads every file in the directory to understand the
whole initiative, and writes one. **Reconciliation is a reader's job** (13.1): a reader merges what
it finds across files, and writers never merge. Anything that must be *agreed* between agents goes
through the orchestrator or a durable store, not through a file two agents both write.

**The rejected alternative, and why.** Copy-edit-merge-delete — each agent copies the shared file,
edits the copy, merges it back, deletes the copy — was rejected on two specific grounds:

- **The merge is an unguarded read-modify-write.** Two concurrent merges both read the same base,
  both write, and the second silently discards the first. No error, no conflict marker, nothing to
  notice. Losing an update quietly is strictly worse than failing to write.
- **A crash mid-merge leaves an orphan copy that no reader can classify.** Is it pending work, or a
  dead remnant? Nothing in the file answers that, so every reader must guess, and some guess wrong.

Single ownership removes both: there is no merge, and a half-written file has exactly one owner who
knows its state. It also degrades well — an agent that dies mid-run leaves one stale file, not a
corrupt shared one.

**Where 13 and 16 divide.** Standard 13 is the concurrency mechanism and binds anywhere agents share
a directory. Standard 16 says which *surface* a fact belongs to, and applies 13's mechanism to the
tier 2 directory. Where they appear to differ, 13 governs: this section is a pointer, not a second
copy of the rule — a restated rule is the same defect as a restated list (16.3).

## 16.5 Lifetime: accumulate, drain, do not reset

A working file **accumulates across prompts within a session** until items are completed out. It is
**not** reset per prompt — a per-prompt reset is the snapshot failure in miniature, discarding the
state that makes multi-prompt work coherent.

Completed items **drain** into a completed-work location, grouped sensibly rather than left as a flat
append log:

```text
${dev-root}/.working-memory/<initiative>/completed/
```

An entry closed by a detour **must** carry the reason it was dropped. That field is required, not
optional: "done" and "abandoned because the premise was wrong" are different facts, and only one of
them tells the next reader not to try it again.

## 16.6 The detour rule

**An agent updates its own file whenever a finding changes the remaining work — not only at prompt
boundaries.**

Prompt boundaries are the wrong trigger because findings do not arrive on them. The moment a finding
makes a listed item wrong, the file is wrong, and it stays wrong for however long the agent keeps
working.

**Two permitted responses:**

1. **Amend the item**, with a one-clause reason. The clause matters: "switch to the X approach" is
   not reviewable, "switch to X, because the Y path needs write access we do not have" is.
2. **Close it out to completed work**, with the reason it was dropped.

**One prohibition: never leave an item silently wrong.** This is the only state where the file
*actively misleads* rather than merely being incomplete. An incomplete file makes a reader look
further. A confidently wrong one makes them stop looking.

## 16.7 Tier 1 — per-project context

**Scope:** one repository. **Location:** that repository's own context pack, per the Perseus layout
already in use. **Written by:** whoever is working in that repository.

Belongs here: what the project is and the shape of its layout; constraints not visible from the code;
decisions local to this repository; where to look for what.

Does not belong here: anything spanning repositories (tier 2); anything durable and general
(tier 3); live per-agent task state (the working file, 16.4).

## 16.8 Tier 2 — cross-repo work in process

**The tier that did not exist, and the real gap.** A migration spanning nineteen repositories had
nowhere to live: tier 1 would have meant nineteen partial copies of one story, and the vault is for
what outlives the work, not the work itself.

**Location:** `${dev-root}/.working-memory/<initiative>/` — one directory per initiative, outside any
single repository, because the initiative is not owned by any one of them.

**Who writes what:**

| File | Owner | Holds |
|---|---|---|
| `initiative.md` | the initiative's owner, one writer | Goal, the repositories in scope and why, the decisions taken, what is explicitly out of scope |
| `<agent-identity>--<session-id>.md` | one agent each | That agent's remaining work and detours (16.4–16.6) |
| `completed/` | drained into by each owner | Closed items, with drop reasons |

**How progress is represented without becoming a stale snapshot.** This is the part that has to be
got right, and the rule is: **progress is derived, never stored.**

- **No percentage, no counts, no "12 of 19 done" anywhere.** That is a materialised number, correct
  once and wrong thereafter — standard 09's volatile-number rule and 16.1's spine, same defect.
- **Progress is read by looking** at what remains across the working files and what has drained into
  `completed/`. The directory *is* the progress.
- **Per-repository state, where it is genuinely needed, is a line in the owning agent's file**, naming
  the repository and its remaining work. One writer per line, amended in place by its owner.
- **A status roll-up is generated on demand and never committed.** The moment it is written down it
  becomes a snapshot competing with the directory it summarised.

**Relation to tier 1 — the one-way dependency, which does apply here.** The workflow/plan ruling
(standard 15) says the durable artefact must not depend on the disposable one. The same shape holds:

> **An initiative file may reference a repository's context. A repository's context must never
> reference an initiative file.**

Tier 1 outlives every initiative that touches it. If a repository's context points at
`.working-memory/<initiative>/`, that pointer dangles the moment the initiative is archived — and
tier 1 has lost the only property that makes it worth keeping. Initiatives come and go; the
repository stays.

**Closing an initiative:** promote the generalisable lessons to tier 3, land anything
repository-specific in the relevant tier 1, then archive the directory. Archiving a directory that
nothing durable points at breaks nothing. That is the dependency direction paying off.

## 16.9 Tier 3 — the Perseus vault

**Durable shared memory**, already in place. The question is only what belongs in it.

**Belongs:** conventions and rulings that bind future work; decisions with their reasoning, so they
are not relitigated; corrections — the wrong answer that looked right, which is the most valuable
category and the easiest to lose; cross-repository facts true independently of any initiative;
terminology, especially where a word is ambiguous.

**Does not belong:** in-flight task state (tier 2); anything scoped to one repository (tier 1);
transcripts; volatile numbers; unverified claims presented as settled.

**Write it with its reasoning.** A rule without its cost is forgettable, and the next agent cannot
tell a considered ruling from an arbitrary one. Record the wrong answer alongside the right one.

## 16.10 Reachability over the tailnet

Verified 2026-10-02, not reasoned about:

- **Tier 3** — the vault answers through the tailnet-published aggregator.
- **Tiers 1 and 2** — the `filesystem` server downstream of that same aggregator reads both. A real
  per-project context file was read end to end over the tailnet URL through the proxy's meta-tools.

**No new component is required.** The reads go through `tool_invoke` because the aggregator is a
lazy-loading proxy; a direct `tools/list` shows only its three meta-tools (see the 1MCP section of
`AGENTS.md`).

**The standing consequence, which is a decision and not a detail.** That filesystem server's allowed
root is the whole development root. Anything on the tailnet that can reach the aggregator can read
**every file under it** — all three tiers, and everything else besides. That is a deliberate trade
with a real cost; narrowing the server's root to the directories these tiers need would reduce it,
at the price of a second server or a narrower one. Recorded so it is chosen rather than inherited.

## 16.11 Agreement with standard 14

Standard 14 governs keepable versus scratch. This standard does not restate it; it names which of its
categories each surface is:

- **Tier 1 context** — keepable, and lives in its repository, so standard 14's worktree rules apply
  as written.
- **Tier 2 working files** — keepable, and deliberately **not** scratch. They do not go in `.temp/`,
  which 14.4 requires to be deleted when a task finishes. These survive until their initiative
  closes, then archive.
- **Tier 2 is not in a repository**, which is why it sits at `${dev-root}/.working-memory/` rather
  than under 14.2's active-worktree rule. 14.3 already contemplates keepable files at the development
  root; this is that case with a named directory instead of a goal-named subfolder, because the
  initiative name *is* the goal.
- **Generated roll-ups** are scratch under 14.4 and are deleted, which is the same conclusion 16.8
  reaches from the snapshot rule. Two rules, one answer.

## 16.12 Review checklist

- [ ] Every fact was placed by the three ordered questions (16.2), not by convenience.
- [ ] No secret, transcript, volatile number, or unverified claim in any tier (16.2.2).
- [ ] No agent wrote the rendered context file; it surfaces agent state by pointer only (16.3).
- [ ] Each agent wrote exactly one file, named from its session start and identity (16.4).
- [ ] The file accumulated across prompts; completed items drained with drop reasons recorded (16.5).
- [ ] Every finding that changed the remaining work produced an amendment or a close-out, with a
      reason — nothing left silently wrong (16.6).
- [ ] No stored progress figure anywhere; progress is derived from the directory (16.8).
- [ ] No tier 1 context references an initiative file (16.8).
- [ ] On closing an initiative: lessons promoted to tier 3, repository facts landed in tier 1, then
      archived (16.8).
- [ ] Tier 2 files are not in `.temp/` and were not deleted as scratch (16.11).

<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# 14 — Agent working directories and file placement

Where an agent puts things. Two failure modes this prevents: files scattered across per-provider
directories nobody can inventory, and scratch output accumulating until nobody dares delete any of it.

## 14.0 How locations are expressed here — the tension, resolved deliberately

This standard is *about* locations, and standard 09 forbids writing absolute paths. Both hold, because
every location below is expressed **relative to a single configured value, the development root**.

- `${dev-root}` is the one configured value. It is supplied by the environment or by the runner; it is
  never written into a document, a script default, or a config file.
- Every other path in this standard is relative to it: `${dev-root}/agents`, `${dev-root}/documents`,
  `${dev-root}/.temp`, `${dev-root}/repositories`.
- **If the tree moves, one value changes and nothing else does.** That is the entire point, and it is why
  a standard about paths can comply with a standard forbidding paths.

Where a reader needs the concrete value, they resolve `${dev-root}` in their environment. Do not
substitute it into any artefact you then commit.

## 14.1 Agent and provider working directories are symlinks into `agents/`

**Rule.** Every agent or provider working directory is a **symbolic link** (or platform-equivalent
directory link) pointing into `${dev-root}/agents`. The real content lives under `agents/`; the
per-provider location in the user profile is only a pointer.

```text
${dev-root}/agents/
  .claude/      .copilot/     .cline/      .grok/      .codex/     ...
```

The provider's expected location — typically a dotted directory in the user profile — becomes a link to
the matching entry. For example, the Copilot working directory in the user profile links to the
`.copilot` entry under `agents/`.

**Why.** Three reasons, in order of how much they hurt when ignored. It makes the set of agent state
**enumerable** — one directory lists every provider rather than hunting the profile. It makes that state
**movable and backup-able** with the rest of the tree. And it means adding a provider is creating one
entry and one link, not discovering a new convention.

**Cautions, learned the hard way.**

- A directory link stores its **target as text**. It does not follow the target when the target moves —
  it silently dangles, and a dangling link often *looks* like an empty directory rather than an error.
  After any relocation, re-point every link and verify each resolves to non-empty content.
- Distinguish link kinds. On some platforms a directory junction needs no elevated privilege while a
  symbolic link does. Prefer whichever form the platform creates without elevation, and record which was
  used.
- **Verify by reading through the link**, not by inspecting the link's own attributes. A link's reported
  size is not the target's size, and a zero reading proves nothing about whether it resolves.
- Never replace a link without first confirming it is genuinely dangling. If it resolves to real
  content, stop.

## 14.2 Files worth keeping go in the active worktree's `documents` folder

**Rule.** A file likely to be kept — a decision record, a plan, a note meant to be read again — is
created and maintained under `documents/` **inside the active worktree**.

**If there is no active worktree, create one.** Do not write keepable files into a base checkout; per
standard 10 the base exists only to track and synchronise with the remote, and work happens in a
worktree beside it.

## 14.3 At a repository root with no worktrees, keepables go to the development root's `documents`

**Rule.** When working at a repository root where no worktrees exist, keepable files go to
`${dev-root}/documents`, **organised into a subfolder** by goal, initiative, or another axis that will
still make sense to someone who was not there.

Name the subfolder after the *goal*, not the date and not the tool. A reader looking for a decision
knows what it was about; they do not know when it happened or which agent produced it.

## 14.4 Scratch work goes to `.temp`, and is deleted

**Rule.** Anything unlikely to be reused — intermediate output, a probe, a one-off report, a scratch
script — goes to `${dev-root}/.temp/<sensible-subfolder>` and is **deleted once used and no longer
needed**.

- Subfolder by task, so concurrent work does not interleave.
- Deletion is part of finishing, not a separate tidy-up later. "Later" does not arrive.
- If something in `.temp` turns out to be worth keeping, **move it** to the right place per 14.2 or
  14.3 rather than leaving it and hoping.
- `.temp` is not a cache and not an archive. If a thing must survive, it is not scratch.

## 14.5 Deciding between keepable and scratch

The test is not how much effort it took. It is: **would a future reader need this to understand a
decision, or to repeat a procedure?** If yes, it is keepable even if trivially small. If it only
supported a conclusion already written down elsewhere, it is scratch even if it was laborious.

Evidence that supports a written claim is the ambiguous case. Keep it, but keep it as a **run log** with
its command and date, per standard 09 — durable text cites the log rather than restating its values.

## 14.6 Review checklist

- [ ] Every agent/provider directory in the profile is a link into `${dev-root}/agents`, and each link
      resolves to non-empty content when read *through*.
- [ ] No absolute path was written into any artefact; locations are relative to `${dev-root}`.
- [ ] Keepable files are in the active worktree's `documents/`, or — with no worktrees — in
      `${dev-root}/documents` under a goal-named subfolder.
- [ ] No keepable file was written into a base checkout.
- [ ] Scratch is under `${dev-root}/.temp/<subfolder>` and was deleted when the task finished.
- [ ] Anything promoted out of `.temp` was moved, not copied-and-forgotten.

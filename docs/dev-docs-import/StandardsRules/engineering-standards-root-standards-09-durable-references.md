<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# 09 — Durable references: no absolute paths, no volatile numbers

Two rules about what may be *written down*. Both exist because written-down facts outlive the
conditions that made them true, and a stale fact is worse than an absent one — it is believed.

Scope: every artefact a human or agent may later read as authoritative. Documentation, standards,
`AGENTS.md`, ADRs, planning docs, run books, commit messages, config, scripts, and durable agent
memory. Not scoped: transient run logs and console output, whose whole purpose is to capture one
moment (see "Where volatile facts belong").

---

## 9.1 Never write an absolute path

**Rule.** Do not record an absolute filesystem path. Express location as repo-relative, or through a
variable or environment indirection that is resolved at use time.

| Instead of | Write |
|---|---|
| a full drive-letter or `/mnt` path to a repo file | the repo-relative path, e.g. `standards/09-durable-references.md` |
| a full path to another repo | `${repos_root}/<repo>/…`, or the repo name plus a relative path |
| a hard-coded home directory | `${HOME}` / `%USERPROFILE%` / `~` |
| a hard-coded tool location | the command name, resolved from `PATH`, or a documented variable |
| a host-specific mount point in a script | a parameter with no default, so the caller must supply it |

**Rationale — this rule was written the day it was earned.** A repository tree was moved between
filesystems, then relocated again within the destination. Every absolute path that had been written
down became wrong at each step: junction and symlink targets, an agent host's allowed-directory list,
an MCP server's sandbox root, a database path in three separate client configs, a launcher script's
config directory, and a service launcher pointing at a home directory that no longer existed. None of
those were bugs when written. They became bugs because the text outlived the layout. The relocation
work was not hard; finding and correcting the written-down paths was, and one dangling reference was
only discovered because an unrelated command failed against it.

**Corollaries.**

- A path that must be absolute at runtime is supplied as **input**, not embedded. Prefer a required
  parameter over a default.
- Where a document genuinely must name a concrete location (a runbook step an operator will paste),
  define it once at the top as a named variable and refer to the variable thereafter. One edit then
  fixes the document.
- Cross-repo references use the repo name and a relative path, never a resolved location.
- This applies to *examples* too. An example containing a real absolute path gets copied.

## 9.2 Never write a number that is likely to change

**Rule.** Do not record a value that is a measurement of the current state. Record the **check that
regenerates it**.

Apply the distinction rather than removing digits blindly:

- **Volatile — do not write.** Counts of files, objects, commits, rows, tables, pages, refs, or
  processes. Sizes in bytes. Durations and timings. Content hashes. Version numbers of things you do
  not control. Anything that would change if the command were re-run tomorrow.
- **Structural — safe to write.** A port a service is configured to bind. A schema version the code
  branches on. A protocol constant. A policy limit that changes only by decision. A count that is
  part of a definition rather than an observation.

| Instead of | Write |
|---|---|
| "the database has 312 pages and 71 tables" | "`page_count` and the table count must match between source and destination — compare before and after" |
| "957 files are dirty, 917 of them line-endings only" | "compare `git diff --numstat`; symmetric added/deleted equal to the whole file indicates line-ending-only churn" |
| "the bundle is 112148 bytes, sha256 4b05…" | "`git bundle verify` must pass and report a complete history" |
| "19 repositories" | "enumerate from the manifest" |

**Rationale.** A recorded measurement invites a future reader to compare against it instead of
re-measuring, and to trust it when it disagrees with reality. It also silently rots: the number is
right for one moment and wrong thereafter, with nothing marking the transition. A check stays correct
indefinitely because it is re-evaluated each time it is read.

**Where volatile facts belong.** In a run log or verification artefact, tied to a timestamp and a
command. Durable text then *cites the artefact* rather than inlining the value. That keeps the
evidence available for audit without making it look like a standing truth.

---

## 9.3 Review checklist

- [ ] No absolute paths. Every location is repo-relative or variable-resolved.
- [ ] No drive letters, no `/mnt/...`, no `/home/<user>`, no `C:\Users\<user>`.
- [ ] Every number is either structural, or replaced by the command that regenerates it.
- [ ] Measurements live in a dated run log, and durable text references that log.
- [ ] Examples obey both rules, because examples get copied.

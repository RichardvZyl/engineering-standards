<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# 12 — Data handling across boundaries

Rules about moving and accessing data where a boundary — a filesystem, an operating system, a process, a
security perimeter — makes the obvious approach wrong.

---

## 12.1 Never copy a database a process may hold open

**Rule.** Do not copy, sync or archive a database file while any process may have it open. **Stop the
writer, take the copy by the owning engine's own rules, and prove the result with that engine.** The
file-level procedure below is the contract for an engine whose state lives in a primary file with a
write-ahead log and sidecars. An engine with a different storage shape — a rollback-journal engine, a
server-managed data directory — is backed up by its own documented facility; its consistency semantics
are not this rule's to invent.

**Why the obvious approach fails.** Where recent committed transactions live in a write-ahead log
alongside the primary file, a database's on-disk state is not confined to that file. Copying the primary
file alone yields a database missing its most recent writes; copying all files while a writer is active
yields a set that is internally inconsistent; restoring a *stale* log next to a *newer* primary file can
corrupt it outright. Engines without that log-and-sidecar shape have their own failure modes and their
own procedure — follow the engine, not this one.

**Incident.** A frozen backup of a store was found holding a multi-megabyte un-checkpointed log beside a
primary file with an older modification time — copied while open. It was demoted to a last-resort artefact
precisely because its internal consistency could not be assumed. The live store, by contrast, was copied
after the daemon was stopped with a verified-empty log, and its integrity check, page count, table count
and row count all matched the source afterwards.

**Ordered procedure — SQLite with a write-ahead log.** These steps rely on SQLite's own documented
invariants: an empty WAL (after a completed checkpoint) means every committed page is in the primary
file, and the `-wal`/`-shm` sidecars are regenerable, so they are never carried to the destination.
They are SQLite's procedure, not a template for every log-shaped engine — a redo/undo log that is *not*
regenerable makes step 4 below destructive rather than safe. For any other engine, use that engine's
own documented backup facility and its own verification; the steps below are not its procedure.

1. Stop the writing process. Confirm by process listing **and** by checking for open handles on the file.
2. Confirm the write-ahead log is empty — that is what proves the content is all in the primary file.
3. Run the engine's integrity check on the source.
4. Copy the primary file and its key material. **Do not copy the `-wal` or `-shm` sidecars** — they
   are regenerable for SQLite, and a stale one is actively harmful.
5. Re-run the integrity check at the destination, and compare structural measures against the values
   captured in step 3 — not against any value written in a document.

**Prefer the engine's own backup facility** where one exists; it is designed to produce a consistent copy
and is safe against a live reader.

## 12.2 Do not access a database across an interop boundary

**Rule.** Query a database **from the platform that owns the file.** Do not reach across a
Windows/Linux interoperability layer, a network share, or any translated filesystem to open it.

**Reason.** These layers do not faithfully implement the advisory file-locking semantics a database engine
depends on. Reads may fail intermittently, and writes risk corruption. The failure is not clean — it
surfaces as sporadic input/output errors rather than a clear refusal.

**Incident.** An investigation into an index inconsistency was blocked twice. Querying the store from the
Linux side while the file lived on the Windows side returned repeated input/output errors, inconsistently —
the first statement in a batch returned no rows and the rest errored, which is worse than an outright
failure because it looks like a result. The same queries ran cleanly once issued from the platform that
owned the file, using that platform's own runtime.

This also disposed of the tempting shortcut of using whichever shell was already open.

## 12.3 Pin line-ending policy per repository; never rely on client configuration

**Rule.** Every repository declares its line-ending policy in tracked attributes. Do not depend on a
per-machine client setting, and do not leave the policy unset.

**Reason.** With no declared policy, the tool compares working-tree bytes literally. An editor that
rewrites a file with different line endings then presents as a whole-file modification with **zero content
change**. The diff is unreadable, blame is destroyed, and the change is invisible to review.

**Incident, recorded in the repository where it happened:** a dozen documentation files presented as fully
rewritten with no content change, and it cost a working session to prove the diff was empty. During the
migration the same condition was found across most of the tree — the large majority of apparently modified
files differed **only** by line ending, because the repositories storing normalised content had no declared
policy while the platform's editors wrote the other convention.

**Practice.**

- Declare the policy in tracked attributes, per repository, including which file types must keep a specific
  convention regardless of platform — interpreter scripts and anything whose digest is checked will break
  otherwise. **This is the only durable fix**, because tracked attributes are platform-independent.
- Where churn already exists, distinguish it from authored work before acting: a whole-file difference whose
  added and removed line counts are equal, and equal to the file's length, is mechanical.
- **Do not change the client conversion setting to "resolve" churn without first reading 12.4.** An earlier
  revision of this standard advised setting it explicitly off. **That advice was wrong and has been
  removed** — on a host whose tooling normalises on checkout, turning it off is what *creates* the churn.

## 12.4 Working-tree cleanliness can be a property of the platform you asked, not of the tree

**Rule.** Before treating a repository as dirty, establish **which platform and which toolchain reported
it**. Where a tree is reachable from more than one platform, ask the platform that owns the files. A
difference in reported cleanliness between platforms is a fact about configuration, not about content.

**Reason.** When a repository declares no line-ending attributes, the client's conversion setting decides
whether the working tree is compared literally or normalised first. Two clients on the same files can
therefore disagree completely: one sees a clean tree, the other sees almost every text file rewritten. Both
are reporting honestly.

**Incident.** A tree of repositories was inspected from a Linux environment, where the conversion setting
was unset, and reported the great majority of tracked text files as modified — characterised as large-scale
line-ending churn requiring a remediation pass before the repositories could be pushed. A renormalisation
step was planned on that basis.

Inspected from the platform that owns the files, **the same repositories were clean**: every remaining
modification was an authored edit, and the mechanical churn was **zero** across every repository. The
difference was a single line in the tooling's **system-level** configuration — installed by the vendor's
own installer, not by the operator, and therefore absent from the per-user configuration that had been
checked. The proposed remediation would have staged hundreds of files for no reason.

**Practice.**

- Enumerate the conversion setting **with its origin**, not just its value. A setting can come from a
  system-level file the operator never edited and would not think to look in. Checking only per-user and
  per-repository scope will miss it.
- State which platform a cleanliness claim came from, whenever a tree is reachable from more than one.
- A remediation whose entire justification is a diff count should be re-measured from the owning platform
  before it is run. Mass staging is hard to unpick and easy to avoid.
- This is the same failure as the database rule in 12.2, in a different subsystem: **the answer depended on
  who was asked.** Generalise accordingly — for any shared tree, identify the owning platform first.

## 12.5 Fix ownership rather than disabling the ownership check

**Rule.** When a tool refuses to operate on a repository because its ownership looks wrong, **correct the
ownership**. Do not add a blanket exemption.

**Reason.** The check exists to stop you executing configuration and hooks out of a tree someone else
controls. A blanket exemption disables it everywhere, permanently, for every repository including ones you
have not seen yet — to silence a message about one.

**Incident.** A tree copied by a privileged process arrived owned by an administrative account, and the tool
refused every repository in it. A per-repository exemption had already been added for one, which is how the
pattern starts. The correct remedy was to reset ownership to the operating user as part of the migration; a
scoped exemption is acceptable as a temporary measure for a single named path, and a global wildcard is not.

## 12.6 Secrets must not sit inside a tree exposed as an agent sandbox root

**Rule.** No credential, token or key file may live inside any directory tree handed to a tool as a
filesystem sandbox root. Keep secrets in the operating system's credential store and inject them into a
process's environment at launch.

**Reason.** A sandbox root is precisely the set of paths an agent may read at will. A credential inside it
is not protected by being unlisted or oddly named — it is enumerable. Obfuscation is not protection: a
base64-encoded token is a token.

**Incident.** An aggregator's credential file sat in its configuration directory **inside the repository
tree**, and the same tree was the sandbox root given to that aggregator's own filesystem server. Any agent
reaching the aggregator could have read the credentials that authenticated its other servers. Moving the
configuration directory out of the tree closed the enumerable path; the plaintext file itself remained, so
the exposure was reduced rather than removed.

**Practice.**

- Store secrets in the OS credential store; have the launcher read them and pass them to the child process
  for that launch only.
- Be honest about the limit: this removes the **filesystem** exposure. It does not stop a local process
  running as the same user from calling the credential API. On a single-user machine that is the realistic
  boundary.
- Per-user environment variables are better than a file in a sandbox root and worse than the credential
  store — they are unencrypted and inherited by every child process.
- **Rotate any secret that has ever been in a sandbox root**, including in backups of it. Moving the file
  does not un-expose what was already readable.
- Never write a secret into a configuration file, a script, a log, a report, a URL or a memory entry, and
  never echo one.

## 12.7 Review checklist

- [ ] No database was copied with its writer still running; a file-backed engine's log was proven empty
      before the copy.
- [ ] No stale log or shared-memory sidecar was restored alongside a primary file.
- [ ] Structural measures were compared before and after, against captured values rather than documented ones.
- [ ] No database was opened across an interop boundary or network share.
- [ ] Every repository declares its line-ending policy in tracked attributes.
- [ ] Any cleanliness or churn claim states which platform reported it, and was re-measured from the owning
      platform before any remediation was run.
- [ ] The conversion setting was enumerated **with its origin**, including system-level scope.
- [ ] Ownership was corrected rather than exempted; no global wildcard exemption exists.
- [ ] No secret resides in any sandbox root; secrets come from the credential store at launch.
- [ ] Any secret previously exposed has been rotated.

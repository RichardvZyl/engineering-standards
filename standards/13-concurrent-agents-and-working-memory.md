<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# 13 — Concurrent agents and working memory

Rules for several agents working at once against a shared tree, and for the files they use to hold
in-flight state. The governing idea: **make conflict structurally impossible rather than resolving it
afterwards.**

---

## 13.1 Single writer per file

**Rule.** Each agent writes **exactly one** working-memory file, and **no agent ever writes another
agent's file.** Every agent may read every file.

**Mechanism.** The filename carries the session start time and the agent identity, so two agents cannot
select the same name even when started in the same moment by the same orchestrator. Working-memory files
live together in one directory per repository so a reader can enumerate them without knowing who is running.

**Why not a shared file with locking.** Locking across agents that may be on different hosts, in different
containers, or crossing a filesystem boundary is exactly where advisory locks stop being reliable — see
standard 12 on interop boundaries. A convention that removes the need for a lock is stronger than a lock
that may not hold. It also degrades well: an agent that dies mid-run leaves one stale file, not a corrupt
shared one.

**Consequence.** Reconciliation is a **reader's** job. A reader merges what it finds across files; writers
never merge. Anything that must be agreed between agents goes through the orchestrator or a durable store,
not through a file two agents both write.

## 13.2 Whole-file writes, never append

**Rule.** Write a working-memory file by replacing its entire contents. Do not append.

**Reason.** A whole-file write is a single operation whose outcome is either the old content or the new one.
An append is a read-modify-write against a file a reader may be scanning, and it accumulates history that
nobody prunes. Since each file has exactly one writer (13.1), replacement loses nothing.

**Caveat worth stating:** "atomic" is a property of the filesystem, not of the intention. Where a write must
survive a crash mid-operation, write to a temporary name in the same directory and rename into place —
rename is the operation with the guarantee. Do not do this across a filesystem boundary, where the
guarantee does not hold.

## 13.3 The detour rule — update your own file when a finding changes the work

**Rule.** When you discover something that **changes the remaining work**, update your own working-memory
file **before continuing**. Never leave a statement standing that you now know to be wrong.

This applies to the plan you are executing as much as to a status list. A bullet that has been invalidated
and left in place is worse than a missing bullet: the next reader — human or agent — will act on it.

**Earned repeatedly in a single migration.** Four separate findings each invalidated a conclusion that had
already been written down and acted upon:

- A file reported as unique content, gating a step, turned out to have been renamed. The gate was wrong.
- An aggregator reported as serving nothing was in fact serving every downstream server through a proxy
  interface; the "nothing loaded" reading came from probing for the wrong thing.
- An embedding backend reported as absent was present and working; the claim came from misreading an
  adjacent diagnostic line.
- A backup verification reported total failure moments before the only other copy was taken offline; the
  harness was at fault, not the artefacts.

In each case the corrected finding **changed what remained to be done**. Had the original statement been
left in place, the next actor would have recovered a file that was not lost, suppressed launchers that were
working as designed, configured a backend that already existed, or abandoned backups that were sound.

**Practice.**

- State the retraction, not just the correction. "This was wrong, and here is why I believed it" prevents
  the same wrong turn; a silent edit does not.
- Retract in the same place the original claim lives, so a reader of that document sees it.
- If the finding changes another agent's remaining work, it goes to the orchestrator — you still do not
  write their file.

## 13.4 A snapshot is not working memory

**Rule.** A rendered or generated context surface is **not** working memory and must not be written to as
if it were. Working memory is authored by the agent that owns it; a snapshot is derived and will be
regenerated, discarding anything written into it.

See standard 11 on snapshots never being a source of truth. The additional point here is directional: do
not **write** into a derived surface, and do not read one as though an agent had authored it.

**Practice.**

- Keep generated context surfaces untracked, and keep working-memory files distinct from them by location
  and naming so the two cannot be confused.
- A generated surface should say in its own text that it is generated and when.

## 13.5 Cross-platform constraints on the working-memory directory

Where agents may run on more than one platform against the same tree:

- **Case.** One platform distinguishes filenames by case and another does not. Two files differing only by
  case will coexist on one and collide on the other. Agent identifiers must therefore differ by more than
  case.
- **Reserved names.** Some names cannot exist as files on some platforms regardless of extension. An agent
  identifier must not be one of them. This is not hypothetical — a file with such a name was found in a
  tree during migration and could not be copied.
- **Path length.** Deeply nested generated paths have been observed exceeding a platform's default limit.
  Keep the working-memory directory shallow and its filenames bounded.
- **Line endings.** Working-memory files are text and are subject to standard 12's line-ending rule.

## 13.6 Review checklist

- [ ] Every working-memory file has exactly one writer, identified in its name along with the session start.
- [ ] No agent writes another agent's file; reconciliation happens on read.
- [ ] Writes replace whole files; any crash-critical write uses same-directory temporary-plus-rename.
- [ ] Every invalidated statement has been retracted in place, with the reason, before work continued.
- [ ] Generated context surfaces are neither written to as working memory nor read as authored.
- [ ] Agent identifiers differ by more than case, avoid reserved names, and keep paths short.

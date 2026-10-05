<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# 11 — Evidence and verification discipline

Rules about **how you come to believe something is true**. Every one was earned by a wrong conclusion
that looked well-founded at the time. The failure mode they share: measuring something adjacent to the
question and reporting it as the answer.

---

## 11.1 Verify a backup with the correct harness before relying on it

**Rule.** Before trusting a backup, verify it **with the tool invoked correctly for that artefact**. If
verification fails, first establish whether the *harness* failed rather than the artefact.

**Incident.** A pre-shutdown check verified every history bundle in a backup set and reported **all of
them failed**. This was moments before deliberately taking the only other copy offline. The bundles were
fine: the verification command resolves an artefact's prerequisites **against a repository**, and the
loop had run from a directory that was not one. Every bundle failed for the same reason, and none of
them was the artefact's.

**What makes this dangerous rather than merely wrong:** a uniform failure across every item is a strong
signal of a harness fault, and a uniform failure is also exactly what genuine media corruption would
look like. The two are indistinguishable from the result alone.

**Practice.**

- A failure affecting **100% of items** is a harness hypothesis first, an artefact hypothesis second.
- Reproduce the failure and **read the actual error text** rather than the exit status. The error named
  the missing repository context explicitly.
- Keep a **known-good control** — an artefact verified clean earlier — and check it under the corrected
  harness. If the control passes and others fail, the failures are real.
- Where a second copy exists on independent media, **compare the copies to each other**. Agreement
  between independently written copies is strong evidence the artefacts are sound whatever the harness says.
- Never take the last independent copy offline on unverified backups.

## 11.2 Path-level absence proves nothing when a rename may be in play

**Rule.** Before asserting a file is missing, absent, or unique to one location, **check whether it was
renamed or moved**. Compare by content and by history, not by path.

**Incident.** A file present in one copy of a tree and absent from two others was reported as unique
content at risk of being lost, and a migration step was gated on recovering it. It had simply been
**renamed into a subdirectory** in a commit, which the history recorded as a rename with high similarity.
The other copies held it at the new path all along. The differing lines were stale path strings, and the
suspicious modification timestamp was a copy artefact, not an edit.

**Practice.**

- Follow the file through history rather than looking only at the current tree.
- Compare **content**, and where a difference exists, characterise it before concluding it is work.
- A timestamp is not evidence of authorship. Identical creation and modification times to sub-second
  precision indicate a copy, not an edit.

## 11.3 Do not infer a subsystem's state from an adjacent line of output

**Rule.** When reading diagnostic output, **match the line to the subsystem by name**. Do not conclude
from a neighbouring line.

**Incident.** A diagnostic reported a language model as absent and unavailable, and on the line
immediately below, an embedding backend as bundled, available, and not degraded. The absent language
model was read as the embedding state, producing the conclusion that no embedding backend existed and
that a backend must be configured. The opposite was true: embeddings were compiled in and working, and
the earlier correct reading had been overturned in favour of the wrong one.

**Practice.**

- Quote the line you are relying on, with its label, when reporting a conclusion from it.
- Two adjacent lines about different subsystems will both look relevant. The label disambiguates; position
  does not.
- When a new reading contradicts an earlier one, **re-derive rather than assume the newer is better.**

## 11.4 Dry-run a vendor wiring command and read the destination it prints

**Rule.** For any command that writes into another application's configuration, **run it in dry-run mode
first and read the destination path**. Treat a path that does not match the platform's real configuration
location as a stop signal. Success output is not evidence it wrote where you expect.

**Incident.** A client-wiring helper resolved a target application's configuration location using another
operating system's convention while running on this one, and would have written a correct configuration
fragment into a path that application never reads. It reports success. Nothing errors. The operator
concludes the client is wired and it is not.

**Compounding detail:** on that machine the target application was **not installed at all**. A wiring
command that "succeeds" against an absent application is doubly misleading. **Confirm the client exists
before wiring it.**

## 11.5 A snapshot is never a source of truth

**Rule.** Any rendered, exported, cached or generated surface is **a snapshot at a moment**. Never treat
it as authoritative, and never let a decision rest on it without re-checking the live source.

This includes rendered context files, cached indexes, generated manifests, exported reports, and any file
whose content was assembled from elsewhere. A snapshot's purpose is to save work, not to settle questions.

**Why this belongs in a standard rather than being obvious:** snapshots are attractive precisely because
they are convenient and look current. A stale one is indistinguishable from a fresh one by inspection —
it has no marker saying when it stopped being true. The cost lands later, on someone who did not generate
it.

**Practice.**

- Where a tool generates a context or summary surface, state in the surface itself that it is a snapshot
  and that load-bearing facts must be verified live.
- A known-stale surface is worse than an absent one, because absence prompts a check and staleness does not.
- If a decision depends on a value read from a snapshot, re-read the value from its origin before acting.

## 11.6 A successful bind is not proof of reachability

**Rule.** When a service reports that it is listening but clients cannot reach it, **enumerate the
operating system's port-forwarding and redirection rules before trusting the process list.** A rule can
shadow a correctly bound local listener.

**Reason.** Binding a socket and receiving connections are different things. A persistent redirection rule
can claim the same address and port and win for matching connections, silently sending them somewhere else.
The service's own log is truthful and useless: it really did bind.

**The signature to recognise:**

- The service logs a successful start on the expected port.
- Connections **time out** rather than being refused. A refusal means nothing is listening; a timeout means
  no answer arrived — most often a forwarder pointing at a dead upstream, but a filtered or dropped SYN
  looks identical. A timeout is evidence to weigh, not proof that something accepted the connection: check
  the redirection rules before concluding a dead upstream.
- A reverse proxy in front returns a gateway error, because it hits the same redirected port.
- The listener's owning process is a **service host**, not the application — because redirection rules are
  implemented by a system networking service rather than by whatever created them.
- It **survives restarting, or entirely shutting down, the subsystem you assume owns it** — because the rule
  is persisted in configuration, not held by a process.

**Incident.** An aggregator service was diagnosed three times and wrongly each time. It logged a clean bind
and reported every downstream component loaded, yet loopback probes timed out and the reverse proxy
returned a gateway error. The listener belonged to a system service host, which produced a theory that a
subsystem forwarder was holding the port and would release when that subsystem shut down. It was shut down
completely. **The listener persisted**, which refuted the theory but left the cause unknown.

The actual cause was a persistent port-redirection rule, created when the service had run inside a virtual
machine, forwarding the loopback port to that machine's address. It was correct when written and became
harmful the moment the service moved to the host. Enumerating redirection rules would have found it in one
command at any point.

**Additional hazard worth recording:** such rules commonly target a virtual machine's dynamically assigned
address. That address is reassigned across restarts, so the rule is broken by design as soon as the machine
returns on a different one. Do not create redirection rules pinned to a dynamic address; and when
retiring a service from a virtual machine to its host, **delete the rules that pointed into it** as part of
the migration rather than leaving them to be discovered.

**Practice.**

- Enumerate redirection rules as an early step in any "it says it is listening but I cannot reach it"
  investigation — before process lists, before logs, before restarts.
- Distinguish timeout from refusal deliberately; they point at different causes.
- When deleting such a rule, delete **only** the one identified. Others may be in active use for unrelated
  purposes.

## 11.7 Absence from a page is not absence

**Rule.** A paginated, truncated, or filtered reply is evidence about **that reply**, not about the
set it was drawn from. Never conclude a thing does not exist because it was not in the output you
happened to receive.

**Read the truncation signal before reading the contents.** Most interfaces tell you: `hasMore`,
`nextCursor`, `totalCount` greater than the number of items returned, a `truncated` flag, an exit
code, a "showing N of M" line. That signal is the first thing to look at and the easiest to skip,
because the content is more interesting than the envelope.

**Confirm absence by addressing the thing directly.** Ask for it by name, by identifier, by path.
A direct request returns a definite answer — it is there, or it is not, and the error says which.
Failing to find something in a list only tells you about the list.

**Why this earns its own rule.** It is not the same failure as a wrong tool or a broken harness
(11.1): here the tool answered **accurately and completely**, and the error was entirely in the
reading. A default page is a design decision made by whoever wrote the interface, for their
convenience and not for your question — and a page boundary falls wherever the data happens to sort,
so a whole category can sit just past it with nothing in the output hinting at that.

**Where it bites hardest:** concluding a capability is missing, a file is gone, a record was never
written, a server is not loaded, or a dependency is absent. All five are claims about a *set*, and
all five get made from a single page.

**Worked example.** A tool catalogue was queried for its contents. The reply held twenty entries,
every one from the same server, alongside `"totalCount": 225` and `"hasMore": true`. The conclusion
drawn was that a different server was **not present at all** — and a capability was nearly reported
as unavailable on that basis. Re-asking with a larger page returned six servers, the "missing" one
among them. Both numbers needed to say otherwise were in the original reply, unread. Addressing the
server by name had worked on the first attempt and would have settled it immediately.

## 11.8 Review checklist

- [ ] Any 100%-failure result was tested against the harness before the artefacts were doubted.
- [ ] A known-good control was checked under the same corrected harness.
- [ ] Independent copies were compared to each other where they exist.
- [ ] No claim of absence was made without checking for a rename.
- [ ] Every conclusion drawn from diagnostic output cites the labelled line it came from.
- [ ] Any configuration-writing command was dry-run and its destination read.
- [ ] No decision rests on a snapshot without the live source being re-checked.
- [ ] For any unreachable-but-listening service: redirection rules were enumerated before the process list
      was trusted, and timeout was distinguished from refusal.
- [ ] No redirection rule targets a dynamically assigned address; rules pointing into a retired virtual
      machine were deleted as part of retiring it.
- [ ] No absence was concluded from a paginated or truncated reply: the truncation signal was read first, and absence was confirmed by addressing the thing directly.

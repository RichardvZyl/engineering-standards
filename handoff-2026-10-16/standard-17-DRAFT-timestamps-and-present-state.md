<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# 17 — A timestamped observation is not present state

Standard 11 collects the ways you can measure something **adjacent to the question** and report it as
the answer. This standard collects a narrower and more expensive mistake: measuring the **right** thing
at the **wrong time**, and reporting a past moment as the present.

---

## 17.1 A record of an event is evidence about that moment, nothing more

**Rule.** An error, a log line, a metric, a status field, a health reading, a test result or a brief's
premise is evidence that something was true **when it was recorded**. Before acting on it, establish
whether it is still true.

This is not a counsel of general scepticism. It is a specific obligation attached to a specific class of
input: anything carrying, or capable of carrying, a timestamp. The obligation is discharged by one
cheap action — **reproduce the symptom now** — and the standard exists because that action feels
redundant when the record looks definitive.

**Why a recorded failure is more dangerous than an absent one.** An absent record prompts an
investigation. A present one supplies a conclusion, a plausible cause, and the comfortable feeling of
having already done the diagnosis. Everything downstream inherits the premise, and no step in the chain
re-examines it, because each step can point at the record.

**What makes it hard to catch:** a stale record and a live one are **identical in form**. The error
text, the severity, the subsystem, the stack — all the same. The only thing that distinguishes them is
a comparison nobody made.

## 17.2 The chronology check

**Rule.** When you find a dated symptom, look for a **dated change that would have resolved it**, and
compare the order. If the change is newer than the symptom, the symptom is a description of the past
until proven otherwise.

This is the operative test and it takes seconds. The symptom has a time. Fixes have times too —
credentials have a written-at, files have a modified-at, commits have a committed-at, packages have an
installed-at, services have a started-at, configuration has a changed-at. Put the two on a line.

Three orderings, three conclusions:

| Ordering | What it means |
|---|---|
| change **after** symptom | the symptom probably describes the window before the change. Re-test before reporting it |
| change **before** symptom | the change did not fix it, or caused it. The symptom stands and the change is now a suspect |
| no change found | the symptom may well be live. Re-test anyway — "no change found" is a claim about where you looked (11.7) |

**The step that is always skipped:** nobody looks for the fix's timestamp, because nobody is looking for
a fix. They are looking at a problem.

**Worked example.** A GitHub aggregator was reported as returning `Bad credentials`, and the brief
treated it as a live fault to be restored. The error was real: `2026-10-02T15:22:28Z`, in the service's
own log, naming the authentication failure exactly.

The credential the service reads was written to the OS secret store at `2026-10-02T15:56:49Z` —
**thirty-four minutes after the error was logged.** The error described the window before the
credential existed. Storing it had fixed the problem, and nothing had failed since.

The cost of not making that comparison was **a day**: a day of treating a resolved failure as an open
one, of building theories to explain it, and of nearly reporting a credential-store integration as the
root cause of a fault that no longer existed. Two timestamps, both already written down, in the same
investigation. The fix was reachable in one subtraction.

**A second instance, same shape, different surface.** A work brief stated that a repository had six
open pull requests nobody was draining, and set a rule about not adding a seventh. The count was
correct when written. By the time it was acted on the count was **zero**, so the constraint it imposed
guarded against nothing and the recommendation it implied was the opposite of the right one. A premise
in a brief is a timestamped observation like any other.

## 17.3 What carries this risk

Anything that was true once and is being read later. The common instances, in rough order of how often
they mislead:

- an error or exception in a log, especially one quoted into a ticket, brief or handover
- a health, status or readiness field — these are *computed at a moment*, often at process start
- a metric, count, quota reading or usage figure
- a test or build result from a previous run
- a brief's or document's statement of fact about a system
- a cached or vendored copy of a reference
- **a local copy of a remote ref**, which is a timestamped observation of a branch and is routinely
  mistaken for the branch

**The process-start trap is worth naming on its own.** A roster, capability list or peer set assembled
when a process started is a snapshot frozen at that instant, and the process will keep serving it with
complete confidence long after a member has gone away. The service is not lying; it is reporting what
was true when it looked.

## 17.4 How this relates to 11.5, and why it is a separate rule

11.5 says a snapshot is never a source of truth: any rendered, exported, cached or generated surface is
a moment, and a decision must not rest on it without re-reading the live source.

**They share one root cause** — a convenient surface looks current and carries no marker of when it
stopped being true — and they are **two rules, because the corrective action differs**, which is the
only thing that makes a standard useful:

- **11.5's correction is to refresh.** The origin still exists and is authoritative. Re-read the value.
- **17's correction is to re-test and to order.** A past event has no live origin — an error from
  15:22 cannot be re-read, and never will be. You cannot refresh an event. What you can do is test the
  *claim it implies* against the present, and compare its time against the times of things that could
  have resolved it.

Put plainly: 11.5 is about a **stale value**, and the fix is a fresh read. 17 is about a **stale
inference from a real event**, and the fix is a new observation plus a chronology. Treating them as one
rule would collapse "re-read it" and "re-test it and check the order" into a single instruction, and
the second is the one that would be lost — it is longer, less obvious, and the one that cost a day.

They should be read together. A record that is both a snapshot *and* an event — a cached health report,
say — is governed by both: refresh the surface, and still do not treat the event it describes as
current.

## 17.5 Practice

- Before acting on a recorded symptom, **reproduce it**. State in the report whether you did.
- Run the chronology check in 17.2. Put the symptom's time and the candidate fix's time side by side in
  the report, so the reader can check the subtraction.
- **Quote times in full, with the zone**, whenever a record is load-bearing. "Recently" and "earlier"
  cannot be ordered against anything.
- When writing a brief, handover or ticket that states a fact about a system, **date the fact**, so the
  next reader can apply this standard rather than inherit the premise.
- Treat a status or roster served by a long-running process as **as-of-start** unless it documents
  otherwise.
- When a symptom cannot be reproduced, say **"not reproducible as of <time>"** rather than "fixed".
  That is what you actually established, and it stays true.
- Where an investigation ends by finding the symptom already resolved, **record the resolving change
  and its time**, not just the conclusion. The next reader needs the comparison, not the verdict.

## 17.6 Review checklist

- [ ] Every recorded symptom acted on in this work was reproduced, or is reported as unreproduced.
- [ ] The chronology check was run: the symptom's timestamp was compared against the timestamp of any
      change that could have resolved it, and both appear in the report.
- [ ] No premise inherited from a brief or earlier document was acted on without re-checking it against
      the system.
- [ ] Load-bearing times are quoted in full with their zone.
- [ ] Any status, roster or capability list read from a long-running process was treated as as-of-start
      unless documented otherwise.
- [ ] Any local copy of a remote ref was refreshed before being read as the remote's state.
- [ ] Where a symptom proved already resolved, the resolving change and its time were recorded.

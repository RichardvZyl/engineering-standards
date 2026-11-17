<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# 17 — Agent execution

How an agent runs work. A rule lives in a file the work is checked against. A script runs
when it is the cheaper reliable method. The agent is told when that script finishes. Work
that can outlive the turn keeps running if the session or the connection goes away.

The governing idea: **the cheapest reliable method runs outside the model, and the model only
reads its result.**

---

## 17.1 Rules live in files the work is checked against

**Rule.** A rule an agent must follow is written in a file the work is checked against. A
conversation is not that file. A memory is not that file.

**Why.** A rule stated only in chat, or only remembered, is absent from the next session,
from review, and from the copy of `standards/` that sync carries downstream. Nothing fails
when it is skipped, so it is skipped. That is the same erosion [`03`](./03-engineering-hygiene.md)
already names for a convention the build does not enforce. The vendoring header on every
file in this set exists for the same reason: a rule that lives only where nobody is looking
is not in force.

**What the work is checked against.** A standard in this set, the repository instruction
file `03` makes binding on the people and assistants in that repository, a test, or a review
checklist. A transcript, an agent memory, or a scratch note can record that the rule was
decided. It does not put the rule in force, even when the wording there is right.

**Practice.**

- Land the obligation in the file that owns it in the same change that decides it.
- One owner. Link to the rule. A second copy will drift, and the drift will still read as
  authoritative.

## 17.2 Script first

**Rule.** Prefer a script whenever it is meaningfully cheaper than performing the work by inference, and the model's only role is to interpret or act on the script's output. All agents must try a script first when the task is suitable, the environment allows it, and the script can be written so that:
- it runs to completion without being interrupted by new messages sent to the invoking agent,
- it leaves no residual processes, windows, or files beyond its explicit report, and
- it includes an explicit, reliable completion signal that the invoking agent can observe (exit code + final status line, a well-known report file, or an equivalent machine-readable marker).
Only if the script fails or is clearly unsuitable should the agent fall back to the next-cheapest reliable method.

**Practice.**

- The three bullets are the suitability test. A task the environment cannot host is
  unsuitable. So is a script that would need a further message to finish, that would leave a
  process or a window or a file behind, or that would end with no signal. The fallback is
  then the next-cheapest reliable method, and only then.
- The explicit report is the signal in the third bullet: the final status line, the report
  file, or the marker. Everything else the script created is residual and is gone before the
  script exits.
- While the script runs, its scratch lives under `${dev-root}/.temp/<task>/`, one directory
  per task (standard 14.4). The report is the exception 14.4 allows until the invoking agent
  has taken the outcome into the place that owns it. After that, the report is scratch and
  is deleted.
- After a successful run the model interprets the output or acts on it. It does not do the
  work the script already did.

## 17.3 Completion is a notice

**Rule.** An agent that starts a script under 17.2 is notified when the script finishes. It
does not poll. Polling is any loop that asks whether the script has finished yet.

**How the notice is delivered.**

- Where the harness can start a background command with no model attached, the agent starts
  the script that way. The harness delivers a completion notice on its own. The agent then
  reads only the summary.
- Where the harness has no completion notice, the script writes the done marker or the report
  file, and a completion message is sent to the invoking agent. The agent reads that message
  and the summary. It still does not poll.

**Why no model is attached.** A model sitting on the running script is how a new message
interrupts it. 17.2 already forbids that. The command runs to its own completion signal. The
model wakes on the notice.

**The summary is the named signal.** It is the final status line, the report file, or the
marker from 17.2, and nothing wider. A neighbouring line is not the signal. A truncated log
is not the signal. Failing to see an expected phrase in a page of output is not the signal.
Standards 11.3 and 11.7 apply here: match the line to the thing it names, read the truncation
before the contents, and confirm completion by addressing the signal the script promised.

## 17.4 Nothing interrupts long work, including a disconnect

**Rule.** Work that can outlive the turn that started it runs detached. It is not a child of
the invoking shell, and it is not a child of the chat. No window is left open for a person to
watch. A new message cannot interrupt it. A disconnect cannot interrupt it either.

**What the job writes, and where.**

- Before the work, an ETA line in its report. The checkpoints below are computed from that
  line, and from nothing else.
- When the work finishes, a marker named `.done` in the same directory.
- The directory is `${dev-root}/.temp/<task>/`, one task per directory, so two jobs cannot
  share a marker.
- The ETA line and the `.done` marker are the explicit report and the completion signal from
  17.2.
- The job is the single writer of both (standard 13.1). The marker is written by creating a
  temporary file in that same directory and renaming it into place (standard 13.2), so a
  reader sees the marker absent or complete.
- The ETA is run-state. It is a number that goes stale the moment it is copied out, so it
  stays in the report. It is never written into a durable document, an instruction file, or a
  memory ([`09`](./09-durable-references.md)).

**The reconnect check.** On disconnect, the agent leaves a check that runs when the connection
is back. The check is itself detached, so the disconnect does not cancel it and a later
message does not either. Its schedule starts from the ETA. A fixed short loop is refused, and
a check every five minutes is that loop. The looks fall around the point where 30% of the
estimated duration remains, then around 20%, around 10%, and at 0. Zero is the estimated
completion, and it is the done check.

Each look is its own detached run. It reads the `.done` marker by name, and then it exits. It
does not sleep in a shell until the next look. A checkpoint whose time has already passed
when the connection returns runs on return, in order. If the marker is absent and the job is
dead, that run resumes the job detached, with the same report and the remaining checkpoints,
and the check itself exits. If the marker is present, the job is done. The check does not
remain as a process, a window, or a file beyond the report.

When the operator returns and starts work, the job is finished, or it has already been
resumed.

**Practice.**

- Long means the run can outlive the turn: a build, a sync, a migration, a backfill, anything
  where the session may end first.
- The checkpoints move only when the job rewrites its own ETA line because the estimate
  changed.
- Resuming reads the marker and the job's state first. Starting a second copy beside a live
  job is not resuming.
- The detached job still obeys 17.2. Once the summary has been taken into the place that owns
  the outcome, standard 14.4 deletes the report.

## 17.5 Review checklist

- [ ] Every rule the agent was required to follow lives in a file the work is checked against.
- [ ] A suitable task was tried as a script first, and the script satisfies the three
      constraints in 17.2.
- [ ] The model interpreted or acted on the script's output.
- [ ] A fallback was used only after the script failed or was clearly unsuitable, and it was
      the next-cheapest reliable method.
- [ ] Completion was taken from a harness notice or a completion message, and only the summary
      was read.
- [ ] The summary was the named signal — exit code and final status line, report file, or
      marker — not a neighbouring line and not a truncated page.
- [ ] Long work ran detached from the shell and the chat, under `${dev-root}/.temp/<task>/`,
      with an ETA line and a `.done` marker renamed into place by the job that owns it.
- [ ] Nothing residual remained beyond that report: no process, no window, no extra file.
- [ ] The reconnect check is scheduled from that ETA at the last 30%, 20%, 10%, and 0. It is
      not a five-minute loop, and each look exits.
- [ ] A checkpoint that came due while disconnected runs when the connection returns, and a
      dead job is resumed detached rather than started a second time.
- [ ] The ETA was not copied into a durable document.

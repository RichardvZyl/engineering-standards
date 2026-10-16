## Timestamps, present state, and choosing a model for A2A

Two rulings, both earned the hard way. Full text in the standards repository: standard 17, and
standard 11.5 which it sits beside.

### A timestamped observation is not present state (standard 17)

An error, log line, metric, status field, test result or **a brief's premise** is evidence about the
moment it was recorded. Before acting on one, reproduce it.

**The check, which takes seconds and is always skipped:** when you find a dated symptom, look for a
**dated change that would have resolved it** and compare the order. Credentials have a written-at,
files a modified-at, commits a committed-at, services a started-at. Put the two times on a line.

- change **after** symptom -> the symptom describes the window before the change. Re-test before
  reporting it.
- change **before** symptom -> the change did not fix it, or caused it.
- no change found -> re-test anyway; "none found" is a claim about where you looked.

Nobody looks for the fix's timestamp because nobody is looking for a fix - they are looking at a
problem. That omission cost a day: a `Bad credentials` error logged at `2026-10-02T15:22:28Z` was
treated as a live fault, while the credential that fixed it had been written at `2026-10-02T15:56:49Z`,
thirty-four minutes later. Both timestamps were already written down in the same investigation.

Also: **a status, roster or capability list served by a long-running process is as-of-start** unless it
says otherwise. It will keep serving a member that has gone away, with complete confidence. And **a
local copy of a remote ref is a timestamped observation of a branch**, not the branch.

How it differs from 11.5: 11.5 is a stale *value* and the fix is a fresh read. 17 is a stale
*inference from a real event* - you cannot re-read an event - and the fix is a new observation plus the
chronology.

### Choosing a model for A2A

The A2A front door is a Google ADK `LlmAgent` named `agentic_data_stack` on loopback 8095, running the
Gemini **alias** `gemini-flash-latest` (not a pinned version). Peers are the subscription CLIs, one
card each.

**The rule:** the router knows exactly one thing about each peer - the text of its card. **Name a model
when the right peer is determined by something that text does not contain. Let A2A route when the right
peer follows from the task as stated.**

Name it when: the constraint is yours not the task's (quota, keeping a provider warm); it is general
coding work, where five peers overlap and the pick would be arbitrary; permission posture matters
(`cline` cannot edit, `agy` auto-denies approvals); the run must be reproducible; or the peer needs
context the task does not carry.

Let it route when the task's own words name its tier - "quick lookup", "summarise", "architecture
review" map onto guidance already in the orchestrator's instruction - and you do not care which peer
answers.

Mechanics worth knowing: naming is honoured exactly, one transfer, no deliberation. A bare "claude"
defaults to `claude-sonnet` and a bare "gemini" to `gemini-flash`, so a bare name is enough when the
default is what you want. The orchestrator turn is nearly free; **the cost of a misroute is the peer
run that follows it.**

**Routing tiers:** deterministic matching first and alone (ADR 0003), a cheap classifier only for what
it could not decide, and the judgement agent only on a trigger. The routing decision is not the work
and must not be priced like it - a routing decision that costs a top-tier turn has reproduced the
overkill it was meant to avoid, one level up where it is harder to see. On genuine ambiguity, route
**up**: over-serving costs bounded quota, under-serving costs a bad answer that propagates. But per-call
price is not task cost, and a model switched mid-task cannot reuse the cached prefix - so recovery gets
more expensive the later it happens, which is the argument for spending at turn zero.

The free, high-value misroute signal: **a human naming a peer immediately after a routed attempt** is a
labelled misroute. Collect it from day one.

> **Forward shape - revisit when buz is installed and its relationship to the A2A node is settled**
> (alongside or replacing). NVIDIA NeMo Switchyard is verified as a product and is a cheap-classifier
> layer, so if it lands behind the node, building that tier by hand is duplicated work; whether it is
> bundled with buz could not be verified. buz is verified and already installed. "one-silo" could not
> be identified by that name at all. No date is given here on purpose: a date expires on its own while
> the condition stays open.

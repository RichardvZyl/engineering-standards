# Recommendation: an intelligent routing model for A2A, tiered

Companion to `workflow-model-routing-tier.md`, which holds the reusable method. This document is the
specific recommendation for this deployment (standard 15: the plan may reference the workflow; the
workflow never references the plan). Paths relative to `${dev-root}` (standard 09).

## What this builds on, and does not relitigate

ADR 0003 in the A2A project folder is **Accepted** and already settles the shape:

- Router and dispatcher are **deterministic services** - project, role and provider by lookup and
  scoring.
- **One judgement agent** rules on escalations and ambiguous intake, with a fallback ladder, and no
  rung grants authority without a policy decision id.

That is the right shape and this recommendation does not reopen it. What it adds is the part ADR 0003
left as a category rather than a choice: *which* model at each tier, *what exactly* triggers
escalation, what being wrong costs in each direction, and how a misroute is detected and recovered.

The owner's own constraint is the design's centre of gravity: **it is overkill for the routing model to
use maximum effort on every route.** Everything below follows from taking that seriously.

---

## The three tiers

### Tier 0 - no model at all

Handles the obvious majority. Costs nothing and cannot hallucinate.

- **Named peer wins outright.** The orchestrator's live instruction already honours this exactly:
  *"If the request names one of these agents ... transfer to exactly that agent once and do not answer
  it yourself."* Tier 0's job is to catch it before any model is consulted.
- **Bare provider names are defaults, not ambiguity.** "claude" resolves to `claude-sonnet`, "gemini"
  to `gemini-flash`. Both are written rules; treat them as tier 0 hits.
- **A small pattern table** for the shapes the card text already discriminates: lookup, summarise,
  extract, reformat go to `claude-haiku`; architecture, deep design, review go to `claude-opus`.
- **Constraint filters, which nothing currently applies.** These are the highest-value lines in the
  whole design because they prevent failures that look like capability problems:
  - request requires file edits -> **exclude `cline`** (plan mode, no auto-approved edits)
  - request will hit an approval prompt -> **exclude `agy`** (auto-denies approval-needing tools)
  - request needs provider-resident memory or skills -> **prefer `hermes`**
  - target peer must be answering -> **exclude peers with no live card**, which today includes a peer
    the front door still advertises

### Tier 1 - one cheap classifier call

Only for requests tier 0 did not decide. Returns `{peer, confidence, reason}`, schema-validated.

**Recommended: `claude-haiku` via the existing peer on 8103.**

**The honest version of this choice: on quality it is close, and quality is not what decides it.** A
pinned Gemini Flash-Lite is cheaper per call and faster, and for a task this constrained - read a dozen
short descriptions, emit one name and a number - both are comfortably capable. Flash-Lite is the better
answer on price alone.

What decides it is **failure correlation.** The node's own orchestrator already runs on the Gemini key,
and that key is returning 429 today. Putting the classifier on the same quota means the router fails in
exactly the circumstance where routing matters most, and it fails the same way: the front door's
fallback gate stalls pending acknowledgement rather than erroring, so a quota problem presents as a
hang in two places at once instead of one. `claude-haiku` is funded by a different subscription, is
already live as a peer, and needs no new credential or endpoint.

Two candidates considered and not recommended:

- **A pinned `gemini-3.x-flash-lite`** - best on cost and latency, rejected on the correlation argument
  above. If the Gemini quota position changes materially, this becomes the better choice and the
  decision should be revisited on that condition.
- **Local Qwen on llama-server** - free, private, no quota, and ADR 0003 already places it near the
  bottom of the ladder restricted to deny/reroute. Too slow to sit in front of every undecided
  request, and the weakest at the one thing tier 1 must do reliably.

**And the recommendation that actually saves the most effort: do not build tier 1 yet.** Build tier 0
and the misroute log first and measure the tier 0 hit rate. Given that naming is already honoured
exactly, that bare names already default, and that the Claude and Gemini tier rules are already
written into the instruction, tier 0 may well decide most traffic. A classifier bought before that
number is known is bought on faith. The workflow's step 1 exists for this reason, and this deployment
is a good example of why.

There is a second reason to wait, in the contingent section below.

### Tier 2 - the judgement agent

ADR 0003's judgement agent, reached only by a trigger firing.

**Recommended: `claude-sonnet`.** It is the configured default tier for "most coding, code review,
reasoning, planning and writing", which includes adjudicating a routing question.

**`claude-opus` is explicitly not the escalation target.** Opus is for the *work*, not for deciding who
does the work. A routing decision that costs an opus turn has reproduced the exact overkill the owner
objected to, one level further up where it is harder to see.

---

## The escalation trigger

Tier 1 escalates to tier 2 when **any** clause holds. Each is checkable without judgement:

1. `confidence < 0.7` - a starting value to be moved from the log, not defended on principle.
2. Two or more peers scored within a narrow band of each other.
3. **The chosen peer's constraints conflict with the request** - edits with `cline`, approvals with
   `agy`, a peer with no live card.
4. **The route would spend a capped tier** - `claude-opus` or `gemini-pro`. Here escalation is cheaper
   than the mistake, so the second opinion pays for itself.
5. The tier 1 reply **failed schema validation**. Ambiguity, never a default.

Clause 3 deserves emphasis: it is the only clause that catches a *confident* wrong answer. The others
all key off the classifier doubting itself.

---

## What being wrong costs, each way

**Routing too cheap** - a wasted peer run, a retry, and a worse answer that may be accepted without
anyone noticing. Cheap per event, expensive in aggregate: an accepted bad answer propagates into
whatever is built on it.

**Routing too expensive** - quota and latency. The answer is still right.

So **ambiguity resolves upward**, the same bias used for the in-progress test in the worktree work, for
the same reason: the cost of over-serving is bounded and visible, the cost of under-serving is
unbounded and invisible.

Two corrections that stop this becoming a licence to always escalate:

- **Per-call price is not task cost.** Switchyard's own documentation makes this point against its own
  pitch: a cheaper model call does not guarantee a cheaper *completed task*. Any claim about routing
  economics stated in per-call prices is not yet an argument. Measure per completed task.
- **Switching mid-task is not free.** A model swapped after several turns cannot reuse the cached
  prefix and pays to re-read the whole conversation. **Recovery gets more expensive the later it
  happens** - which is the argument for spending at turn zero rather than on recovery machinery.

---

## Detecting a misroute

Use what the system already emits. `a2a/peers/cli-peers/logs/runs.jsonl` already records peer, event,
task id, context id, turn, caller and prompt size. It needs three fields added: **outcome, duration,
and the routing decision** (`tier`, `confidence`, `reason`) - in the same record, so decision and
outcome can be joined.

Four signatures, none requiring a quality model:

1. The peer errored, returned empty, or failed its own validation.
2. **The same caller re-asked within the same `contextId`** shortly after a reply. A retry is a
   dissatisfaction signal.
3. The run exceeded a per-peer duration budget.
4. **A human named a peer immediately after a routed attempt.**

Signature 4 is the most valuable thing in this design and it is free. It is a **labelled misroute**:
the route taken, the route wanted, and the request that distinguishes them. Collect it from day one,
before any classifier exists - it is the only dataset that can tune the 0.7 threshold into something
defensible, and it is also the evidence that decides whether tier 1 is needed at all.

---

## Recovering from one

- Escalate **once**, to the peer the trigger names.
- Re-send the **original request**, never the weak peer's output. Anchoring a stronger peer to a weaker
  one's answer is a real degradation and an easy mistake to make while trying to save tokens.
- **Cap at one escalation per task.** A second means the rule table is wrong: record `needs_human` per
  ADR 0003 rather than looping. A loop turns a routing bug into a quota incident.
- No automatic escalation reaches `claude-opus` or `gemini-pro`. ADR 0003 already requires a policy
  decision id for authority; spending the top tier is exactly that kind of decision.

---

## Build order

1. Tier 0, including the constraint filters - the highest value per unit of effort in the whole design.
2. The misroute log, with signature 4 collected from the first day.
3. Nothing else until the tier 0 hit rate and the labelled misroutes are in hand.
4. Then, and only then, tier 1 - if the numbers justify it and the contingent question below has
   resolved.

---

## Contingent on the forward shape

**The durable part of this recommendation is above this line.** Tier 0, the trigger conditions, the
cost asymmetries, the detection signatures and the recovery discipline hold regardless of what lands.

**NVIDIA NeMo Switchyard is a cheap-classification layer, which is to say it is tier 1.** It is real
and open-source: a proxy between an API endpoint and the models, preserving OpenAI and Anthropic API
compatibility, shipping several routing algorithms and operational metrics. If it lands behind the A2A
node as planned, **building tier 1 by hand is duplicated work** - and that is the second reason to
defer it. What Switchyard does not provide is tier 0's constraint filters, which encode facts about
*these* peers' permission postures that no general router can know. Those remain ours either way.

Unverified, and marked as such:

- **Switchyard bundled with buz** - no source found linking them. Switchyard is vendored into NVIDIA's
  own NeMo Platform as a plugin, so "bundled" has precedent with NeMo rather than with Buzz.
- **one-silo** - no product of that name could be identified. If it is real, the name here differs
  from its shipped name, or it is private.
- **buz itself is verified and already installed** - Block's Nostr-based agent workspace, binaries
  present under `Buzz/`. It fronts existing harnesses rather than replacing peers, so it changes who
  owns the misroute log, not what the log contains.

### Update trigger

> **Revisit this section when buz is installed and its relationship to the A2A node is settled.**
> Revisit the tier 1 recommendation **when Switchyard is reachable behind the node** - at which point
> tier 1 becomes configuration of Switchyard rather than a model choice. Revisit the `claude-haiku`
> versus Flash-Lite choice **when the Gemini quota position changes materially**, since that choice
> turns on failure correlation and nothing else.

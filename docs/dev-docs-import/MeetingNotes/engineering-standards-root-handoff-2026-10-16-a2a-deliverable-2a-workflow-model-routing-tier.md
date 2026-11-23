# Workflow: designing or revising a model-routing tier

Generic and reusable. It names no specific deployment, model or plan (standard 15). Paths are relative
to `${dev-root}` (standard 09).

## When to use it

A system must decide which of several models or agents handles each request, and the decision is
currently either hardcoded, absent, or made by a model expensive enough that the decision costs a
noticeable fraction of the work.

## The principle the whole workflow rests on

**The routing decision is not the work, and must not be priced like it.** A router that reasons hard
about every request has moved the cost it was built to save. The correct shape is a cheap path that
handles the obvious majority and an expensive path that handles only genuine ambiguity - and the design
question is never "which model should route?" but **"what fraction of requests need a model at all?"**

## Steps

### 1. Measure the free tier before designing the paid one

Before choosing any classifier, count how many requests are decided with **no model**:

- the request names its target explicitly
- the request matches a compiled pattern with a single obvious target
- there is only one target capable of the request

Instrument this first and run it for a representative period. **If deterministic matching covers the
large majority, a classifier may never repay its own cost**, and the honest deliverable is a rule table
plus a log. Designing tier 1 before measuring tier 0 is the most common way this work wastes effort.

### 2. Make the cheap tier's output structured and validate it

The cheap tier returns a target, a confidence, and a one-line reason. Validate against a schema.

**A validation failure is ambiguity, never a default.** A malformed classifier reply that silently
falls through to a default target is a misroute that leaves no trace, which is the worst of the
available outcomes.

### 3. State the escalation trigger as conditions, not as judgement

Escalation must be checkable by something that cannot think. Each clause is a predicate:

- confidence below a stated threshold
- two or more targets scored as equally fit
- the chosen target's **constraints conflict with the request** - it cannot perform an action the
  request requires, or it is barred from one the request implies
- the request would consume a **capped or expensive** resource, where a second opinion costs less than
  the mistake
- the cheap tier's output failed schema validation

Start the threshold at a round number, then move it from the misroute log rather than from intuition.
A threshold that has never been revised from data is a guess wearing a number.

### 4. Price being wrong in both directions, separately

These are not symmetric and treating them as symmetric produces a bad bias:

- **Routing too cheap:** a wasted run, a retry, and a worse answer that may be accepted silently.
  Cheap per event; expensive in aggregate, because accepted bad answers propagate into later work.
- **Routing too expensive:** quota and latency. The answer is still correct.

So on genuine ambiguity, **ambiguity resolves upward**. The cost of over-serving is bounded and
visible; the cost of under-serving is unbounded and invisible.

Two corrections that stop this becoming a licence to always escalate:

- **Per-call price is not task cost.** A cheaper call that needs three retries, a longer trace and a
  failed tool call can cost more than one correct expensive call. Measure cost per *completed* task.
  Any routing claim stated in per-call prices is not yet an argument.
- **Switching mid-task is not free.** A model swapped after several turns cannot reuse the cached
  prefix and pays to re-read the whole conversation. Therefore **recovery gets more expensive the
  later it happens**, which is the argument for spending more at turn zero than on recovery machinery.

### 5. Detect misroutes from signals you already emit

Do not build a quality model. Use the four signatures that cost nothing to collect:

- the target returned an error, an empty result, or failed its own validation
- the **same caller re-asked within the same context** shortly after a reply - a retry is a
  dissatisfaction signal
- the run exceeded a per-target duration budget
- **a human named a target immediately after a routed attempt**

The last is the highest-value signal in the system and is free. A human overriding a route is a
**labelled misroute** - the route that was taken, the route that was wanted, and the request that
distinguishes them. Collect these from day one, before any classifier exists; they are the only
dataset that can tune the threshold in step 3.

### 6. Make recovery bounded and single-shot

- Escalate **once**, to the target the trigger names.
- Re-send the **original request**, not the weaker target's output. Feeding a weak answer to a strong
  model anchors it to the weak answer; this is a real and frequently-missed degradation.
- **Cap at one escalation.** A second means the rule table is wrong. Record it as needing a human
  rather than looping - a loop converts a routing bug into a quota incident.
- Never let an automatic escalation reach the most expensive target. Spending the top tier is a policy
  decision and should carry a recorded decision identifier.

### 7. Log the decision next to the work

The routing decision and the run it caused must appear in **one** record: target, tier that decided,
confidence, reason, outcome, duration. A decision logged separately from its outcome cannot be joined
later, and an unjoinable log cannot answer whether the router is any good.

### 8. Check whether something already does this

Routing is a solved-enough problem that purpose-built components exist, including open-source proxies
that preserve common API compatibility and ship routing algorithms and metrics. **If one of those is
already planned for the stack, building a bespoke cheap tier is duplicated work** - build the rule
table and the log, and let the component own classification when it arrives.

## Failure modes this workflow exists to prevent

- Reasoning hard about every route, so the router costs what the work costs.
- Choosing a classifier before measuring how many requests need one.
- An escalation trigger stated as judgement, so it is never applied consistently.
- A malformed classifier reply silently taking a default.
- Treating the two directions of error as equally costly.
- Arguing routing economics in per-call prices instead of per-completed-task.
- Escalating in a loop instead of stopping at one and asking for a human.
- Re-sending the weak answer instead of the original request.
- Building a classifier that a planned component was going to provide anyway.

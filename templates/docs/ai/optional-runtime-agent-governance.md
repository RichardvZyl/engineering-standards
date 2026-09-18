# Optional: runtime agent governance (AGT)

<!-- SEEDED ONCE from engineering-standards. Suggestion only. Delete this file
     if unused. Nothing in standards/ requires AGT. -->

**Status:** optional / watch-list. Not a dependency. Not vendored. Do not treat
as required for every repository.

The [Agent Governance Toolkit](https://github.com/microsoft/agent-governance-toolkit)
(AGT) is runtime policy, identity, and sandboxing for **agent hosts**. It
intercepts tool calls, message sends and delegation in application code —
policy, identity, and an audit trail — rather than asking the model to behave.

That is a different plane from vendored conventions. `standards/` says how
people and assistants work in a repository. AGT says what a running agent is
structurally allowed to do. One does not imply the other.

## When to use

Reach for it when the host can do something that is expensive to reverse
without a gate in front of the wire:

- money moves
- email / send on behalf
- destructive tools
- multi-agent fleets

## When it is not required

Everyday coding agents — the kind whose host already has review: a pull
request, a human merge, a CI gate. Host-level review is the control surface
those agents already have. AGT is not a missing standard in that shape.

## Rollout

Pilot on **one** agent host before fleet-wide. A toolkit that denies tool
calls will surprise you the first time; better that surprise is one host.

Same posture as the other optional notes: suggestion, not a vendored mandate.
Do not install it because a repository follows these conventions.

## Upstream

https://github.com/microsoft/agent-governance-toolkit

# Choosing a model for A2A, and when to let A2A choose

Everything in Part 1 and Part 2 is grounded in the configuration and runtime of the A2A node as it
stands. Part 3 is contingent on a shape that has not landed and says so. Paths are relative to
`${dev-root}` (standard 09).

---

# Part 1 - What is actually there

## 1.1 The node

| | |
|---|---|
| Agent name | `agentic_data_stack` (card version 1.0.0) |
| Framework | Google ADK for TypeScript, `@google/adk` 2.2.0 |
| Shape | one `LlmAgent` mounted with `toA2a`, peers attached as `RemoteA2AAgent` sub-agents |
| Listener | loopback port 8095 |
| Source | `Agents, IDE's, Tools, Services/Development Tools/AgenticStack/agentic-data-stack/a2a` |

## 1.2 The model it runs - confirmed, with one honest gap

**Configured: the alias `gemini-flash-latest`.** Proven at `a2a/src/agent.ts`:

```ts
export const GEMINI_MODEL = 'gemini-flash-latest';
```

Two environment variables can change that, and **neither is set**:

- `A2A_LLM_BACKEND` - `local` or `gemini`. Unset, so the backend is chosen by key presence.
- `A2A_MODEL` - used as the Gemini model when its value starts `gemini-`, and as the local model id
  when it does not. Unset, so `GEMINI_MODEL` stands.

The key is present: the process reads Windows Credential Manager generic target
`A2A/GOOGLE_GENAI_API_KEY` at startup when the environment variable is absent, and that entry exists.
So the backend is Gemini and the model is the alias.

**The correction worth having: there is no version pin at all.** The belief that the node runs Gemini
3 Flash or Gemini 3 Flash Lite names a specific version, and no specific version is configured. What is
configured is a Google-maintained alias that Google re-points as new Flash releases ship.

**What the alias currently resolves to is unconfirmed from this machine, and that is a real unknown
rather than a formality.** Two things were tried:

- `GET /v1beta/models/gemini-flash-latest` returns `version: "Gemini Flash Latest"` - self-referential.
  The metadata endpoint does not disclose the concrete target. It does give the limits: **1,048,576
  input tokens, 65,536 output**.
- `generateContent` **does** report the concrete target in its `modelVersion` field. Three attempts
  returned HTTP 429.

**What would confirm it:** one successful `generateContent` call against `gemini-flash-latest`, reading
`modelVersion` off the response. One line, once quota allows. Nothing else gives a reliable answer,
because the alias does not describe itself.

Published behaviour of the alias, which is the part that matters for design:

- It is hot-swapped with each new Flash release, with notice given for breaking changes.
- **It has already moved more than once.** Google's release notes named 3.5 Flash as the target at one
  point; a later developer report shows `gemini-3.8-flash`.
- **It can break outright.** An ADK issue records the alias returning 404 after the specific model
  behind it was retired. An alias is not a stability guarantee; it is the opposite.
- Pinned Flash-family models are available on this key, including several 3.x Flash and Flash-Lite
  releases, all at the same 1M/64K limits.

**Recommendation on the alias:** pin `A2A_MODEL` to a concrete Flash id and move it deliberately. The
orchestrator's whole job is to read peer descriptions and emit one `transfer_to_agent` call - it does
not need the newest model, it needs a model whose behaviour does not change under it. An alias trades a
stability property you want for a capability property you do not.

## 1.3 A live operational finding

The Gemini key is returning 429 right now. That matters more than it looks, because the node does
**not** silently fall back: the model is wrapped in `GeminiWithAcknowledgedLocalFallback`, and when
Gemini cannot continue the server emits an `acknowledge_local_fallback` call and the task stays
`input-required` until the client answers `acknowledged=true`. So under quota exhaustion the front door
**stalls pending acknowledgement rather than degrading to local**. That is the designed behaviour and it
is the right design, but it means a throttled key presents as a hang, not as an error.

## 1.4 The clients

Observed at the time of writing, and per 11.5 this table is a snapshot - re-read it live before relying
on it. The live check is a `GET` of `/.well-known/agent-card.json` on each port.

| Peer | Port | What it actually is | What its card says to pick it for |
|---|---|---|---|
| `claude-haiku` | 8103 | Claude Code CLI, `--model haiku` | trivial work: short replies, lookups, summaries, extraction, reformatting |
| `claude-sonnet` | 8104 | Claude Code CLI, `--model sonnet` | most coding, code review, reasoning, planning and writing |
| `claude-opus` | 8105 | Claude Code CLI, `--model opus` | only when named, or clearly hard: architecture, deep design, review. Never simple tasks |
| `claude` | 8101 | alias card for `claude-sonnet` | direct callers; the tier cards are preferred |
| `cursor` | 8102 | Cursor Agent CLI, `cursor-agent -p` | coding: writing, explaining, refactoring, shell/IDE-style help |
| `gemini-flash` | 8106 | Gemini CLI, `-m flash` | quick Google-model answers; where a bare "gemini" goes |
| `gemini-pro` | 8107 | Gemini CLI, `-m pro` | only when named or clearly hard |
| `cline` | 8108 | Cline CLI, `--json --plan` | coding questions. **Plan mode: no auto-approved edits** |
| `devin` | 8109 | Devin CLI, `-p --permission-mode auto` | coding and engineering. **Read-only tools auto-approved** |
| `grok` | 8111 | Grok Build CLI, default grok-4.7 | xAI answers, coding, reasoning |
| `agy` | 8112 | Google Antigravity CLI, `agy -p` | Antigravity coding help. **Approval-needing tools auto-denied** |
| `openclaw` | 18789 | OpenClaw gateway main agent | gateway-routed work |
| `hermes` | 8113 | Hermes gateway, Nous | memory and skills; also the Telegram-side assistant |
| `qwen` | 8110 | local coder on llama-server | only when named, or when local/offline is wanted |

Two gaps between the roster and reality, both worth knowing:

- **`hermes` is in the front door's roster but served no card when checked.** The roster string is built
  once at process start from the peers whose card URLs were set and reachable *then*. It is a
  start-time snapshot, and the orchestrator will happily try to transfer to a peer that has since gone
  quiet. This is standard 17 biting inside the system itself.
- **`qwen` is configured but not attached** - opt-in, its card URL unset, not listening.

The LibreChat endpoints and the ClickHouse MCP servers declared in `providers.json` attach only when
their `A2A_*_AGENT_CARD_URL` is set to an absolute URL. None of them appear in the live roster, so they
are declarations, not peers.

## 1.5 The framing, tested

"Claude is the thinking model, Cursor the workhorse" is a reasonable starting point and the
configuration partly disagrees with it.

**Claude is configured as both.** `claude-opus` is the thinker and its card explicitly forbids it for
simple tasks. But `claude-sonnet` is configured as the general workhorse - "most coding, code review,
reasoning, planning and writing" - and it is where a bare "claude" lands. Treating Claude as
thinking-only leaves the tier that is actually configured to do the bulk of the work unused.

**"Cursor the workhorse" holds for cursor, and under-describes the problem.** There are **five**
functionally overlapping coding peers: `cursor`, `cline`, `devin`, `grok`, `agy`. Their card
descriptions differentiate them by provider name and permission posture, not by capability - "pick for
coding tasks", "pick for coding questions", "pick for coding/engineering tasks". The router has no
basis in that text to prefer one over another.

**So the sharp consequence: for general coding work, the router's choice among those five is close to
arbitrary.** Naming a peer there is not an optimisation; it is the only way to get a determinate answer.

**And the real discriminator among them is permission posture, which the router is never told to reason
about:**

- `cline` runs in plan mode with no auto-approved edits - **wrong for anything that must change files.**
- `agy` auto-denies anything needing approval - **wrong for anything that will hit a prompt.**
- `devin` auto-approves read-only tools - safe for investigation, bounded for mutation.

Those three facts are in the card text, and nothing in the orchestrator's instruction asks it to weigh
them. A router asked for "refactor this module" can pick `cline`, which cannot edit, and the failure
will look like a capability problem.

---

# Part 2 - The decision rule

## 2.1 The rule

> **The router knows exactly one thing about each peer: the text of its card. Name a model when the
> right peer is determined by something that text does not contain. Let A2A route when the right peer
> follows from the task as stated.**

That is the whole rule. Everything below is how to apply it without thinking.

## 2.2 Name the model when any of these is true

1. **The constraint is yours, not the task's.** Protecting a subscription cap, deliberately spending a
   cheap tier, keeping one provider warm, avoiding a provider that is throttled. The card text cannot
   express your quota position.
2. **It is general coding work.** Five peers overlap; the pick would be arbitrary. Name one.
3. **Permission posture matters.** The work must edit files - not `cline`. The work will hit an approval
   prompt - not `agy`.
4. **The run must be reproducible or auditable.** A named peer is a string match in the orchestrator's
   instruction and is honoured exactly. A routed peer is a model's judgement and may differ next time
   on the same words.
5. **The peer needs context the task does not carry** - a repo it already knows, a prior session,
   memory that lives with one provider (`hermes`).

## 2.3 Let A2A route when both of these are true

1. **The task's own words name its tier.** "Quick lookup", "summarise this", "reformat that",
   "architecture review" map directly onto the haiku / sonnet / opus guidance already in the
   instruction. The router is not guessing there; it is following a rule it was given.
2. **You do not care which peer answers, only that one does.**

## 2.4 The mechanics that make the rule cheap to apply

These are quoted from the orchestrator's live instruction, not inferred:

- Naming is honoured exactly: *"If the request names one of these agents ... transfer to exactly that
  agent once and do not answer it yourself."*
- A bare **"claude" goes to `claude-sonnet`**. A bare **"gemini" goes to `gemini-flash`**. Those are
  defaults written into the instruction, not inference - so a bare name is a *weak* form of naming, and
  it is enough when the default is the one you want.
- When the router picks a Claude tier itself it is told: haiku for trivial, sonnet for most coding and
  reasoning, opus never unless asked or clearly hard.
- Letting it route costs **one orchestrator turn on the Flash alias before any work starts**. Naming
  costs none - but see 2.5, because that turn is not where the money is.

## 2.5 What a misroute actually costs

The orchestrator turn is nearly free. **The cost of a misroute is the peer run that follows it**, and
occasionally a human's time reading a worse answer and not noticing. Optimise the decision, not the
deliberation: it is worth more care at turn zero than anywhere later, because a model switched mid-task
cannot reuse the conversation's cached prefix and pays to re-read all of it.

---

# Part 3 - Contingent on a shape that has not landed

**Everything above holds whichever way this resolves. Nothing above depends on this section.**

Three changes are expected. Here is what could be verified and what could not.

**NVIDIA Switchyard - verified as a product, unverified in this deployment.** It is real: NVIDIA NeMo
Switchyard, an open-source Apache 2.0 model-routing library, a proxy that sits between an API endpoint
and the models, preserving OpenAI and Anthropic API compatibility, with several routing algorithms and
operational metrics. Coverage dates to around August 2026. NVIDIA's own cost claims are vendor figures
and are not independently verified; its README carries the caveat that matters most here - **a cheaper
model call does not guarantee a cheaper completed task.** A community caveat worth keeping: switching
model mid-task forces a full prefill of the prefix again, so there is no free re-routing once a task is
under way. Whether it will sit behind the A2A node here is a plan, not an observation.

**buz - verified, and already on disk.** This is Buzz by Block: an Apache 2.0, Nostr-based workspace
where agents hold their own cryptographic keypairs and join channels as members with their own
presence and audit trail. It is not tied to one model and is designed to front existing harnesses.
Binaries are already installed at `Buzz/` - `buzz.exe`, `buzz-agent.exe`, `buzz-acp.exe`,
`buzz-dev-mcp.exe`, `buzz-desktop.exe`, plus `git-credential-nostr.exe` and an `identity.ncryptsec`
key file. `buzz-agent` is an ACP client and `buzz-acp` is the bridge to harnesses such as Claude Code,
Codex and goose. So buz will not replace the *peers*; it is a different front door onto the same CLIs.

**"Switchyard bundled with buz" - could not be verified.** No source found linking the two. What does
exist is a Switchyard copy vendored into NVIDIA's own NeMo Platform as a plugin, and a NeMo Relay
plugin - so "bundled" has precedent, with NeMo rather than with Buzz. Treat the bundling as an
expectation, not a fact.

**one-silo - could not be verified at all.** No product by that name was found. If it is a real
component, its name here is likely different from the one it ships under, or it is private.

### What changes if the shape lands

- If **Switchyard** sits behind the node, it takes over the *cheap classification* layer described in
  the routing recommendation. The decision rule in Part 2 does not change: it governs whether a human
  or agent names a peer, which is upstream of whatever picks when no peer is named.
- If **buz** replaces the node, the peer roster survives and the front door changes. Part 2's rule
  survives with "card text" re-read as "whatever description the new front door exposes". The
  permission-posture point survives unchanged, because it is a property of the CLIs.
- If **buz** sits alongside, there are two front doors over one peer set, and the only new question is
  which one owns the misroute log.

### Update trigger

> **Revisit Part 3 when buz is installed and its relationship to the A2A node is settled** - alongside
> or replacing. Revisit the Switchyard paragraphs **when Switchyard is actually reachable behind the
> node**, at which point the cheap-tier recommendation moves to it. Revisit the one-silo paragraph
> **when one-silo can be identified by its shipped name.**

No date is given deliberately: a date would expire on its own while the condition stayed open.

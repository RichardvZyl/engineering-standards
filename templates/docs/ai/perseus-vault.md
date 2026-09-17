# Dependency: Perseus / Vault

<!-- SEEDED ONCE from engineering-standards. This is required wiring for agent
     hosts under this kit, not a suggestion. Edit the stubs; do not delete the
     dependency. MCP install steps do not belong in standards/. -->

**Status:** dependency for agent hosts. Not optional. Not vendored into
`standards/` — those files stay engineering conventions. Seed this wiring
once from `templates/`.

Agents working under these standards require **Perseus Context Engine** and
**Perseus Vault**.

| Piece | What it is | What the host must expose |
|---|---|---|
| Context Engine | Repo-local briefing | MCP `perseus` and `.perseus/` in the repository |
| Vault | Shared memory across repositories on this machine | MCP `perseus_vault_*` |

- **Vault:** session start `perseus_vault_context`. Durable facts
  `perseus_vault_remember`. No secrets.
- **Context Engine:** `.perseus/context.md` is this repository's briefing.
  Do not reuse another project's briefing.

## Scaffolding

Copy `templates/perseus/` to `.perseus/` at the repository root:

- `context.md` — repo-local briefing
- `pack.yaml` — render pack; synthesis probes start disabled

That copy is expected scaffolding, not a toy. Fill the placeholders. Ignore
generated output (`.perseus/cache/`, `live-context.md`).

`standards/` does not install MCP servers and a standards sync will not create
`.perseus/`. The host still has to expose the tools. The dependency is the
wiring, not a new numbered standard.

## What this is not

APM, agentrc, and AGT remain **optional** watch-list notes. They are not this
dependency. See `docs/ai/optional-*.md`.

A Perseus render is a snapshot. It does not overwrite `AGENTS.md` or
`standards/` pointers.

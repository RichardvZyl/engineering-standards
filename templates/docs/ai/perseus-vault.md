# Optional: Perseus / Vault

<!-- SEEDED ONCE from engineering-standards. Suggestion only. Delete this file
     if unused. Nothing in standards/ requires Perseus or Vault. -->

**Status:** optional / watch-list. Recommended wiring only when the host has
the stack. Not a dependency. Not vendored.

**Conventions stay mandatory. Perseus is not.** `standards/` does not name
Perseus, Vault, or any other memory host. A consuming repository that never
creates `.perseus/` is still following the standards. A standards sync will
not add it, and must not be read as requiring it.

| Piece | What it is | What the host exposes, if present |
|---|---|---|
| Context Engine | Repo-local briefing | MCP `perseus` and `.perseus/` in the repository |
| Vault | Shared memory across repositories on this machine | MCP `perseus_vault_*` |

- **Vault:** session start `perseus_vault_context`. Durable facts
  `perseus_vault_remember`. No secrets.
- **Context Engine:** `.perseus/context.md` is this repository's briefing.
  Do not reuse another project's briefing.

## When to seed it

Only if the agent host actually exposes Perseus / Vault tools. Copy
`templates/perseus/` to `.perseus/` at the repository root, then edit.
Ignore generated output (`.perseus/cache/`, `live-context.md`).

That copy is an **optional seed**, not required scaffolding for every
consumer. Delete the stubs if the host does not have the stack.

## When not to

- The host has no Perseus tools. Do not add `.perseus/` as decoration.
- You were about to treat `.perseus/` as part of the synced set. It is not.
  `Sync-Standards.ps1` writes only inside `standards/`.

## Dual source of truth

Do not let a generated briefing overwrite `AGENTS.md` or `standards/`
pointers. Perseus renders a snapshot; the authored files remain the source
of truth. Same cutover rule as APM and agentrc: if something else becomes
the writer for those files, that is a deliberate migration, not an add-on.

Same posture as the other optional notes — suggestion, not a vendored
mandate.

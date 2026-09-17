# AI documentation

<!-- SEEDED ONCE from engineering-standards. `domains/` and the Perseus
     dependency stay. The `optional-*.md` files may be deleted. -->

`domains/` holds bounded-area vocabulary, routed from `AGENTS.md`. Copy
`_template.md` per area, then delete the unfilled template.

## Dependency

| Note | Role |
|---|---|
| [Perseus / Vault](./perseus-vault.md) | Required agent-host wiring: MCP `perseus` + `perseus_vault_*`, `.perseus/` in the repo. Seed from `templates/perseus/`. Not a numbered standard. |

## Optional (watch-list)

The `optional-*.md` files are **suggestions**, not conventions. `standards/`
does not mention them and a standards sync will not install them. A live
canonical skill or config tree stays the writer for those paths; these tools
are never a second source of truth alongside it.

| Note | Upstream |
|---|---|
| [Agent Package Manager (APM)](./optional-agent-package-manager.md) | https://github.com/microsoft/apm |
| [agentrc](./optional-agentrc.md) | https://github.com/microsoft/agentrc |
| [Runtime agent governance (AGT)](./optional-runtime-agent-governance.md) | https://github.com/microsoft/agent-governance-toolkit |

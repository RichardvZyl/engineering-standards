# Perseus scaffolding

<!-- SEEDED ONCE from engineering-standards. Expected scaffolding for the
     Perseus / Vault agent-host dependency. Copy to `.perseus/` at the
     repository root, then edit. Not vendored. standards/ does not install
     MCP servers. -->

Copy these files to `.perseus/` when seeding a repository that follows this
kit. Agents working under these standards require that directory.

- `context.md` — repo-local briefing template
- `pack.yaml` — render pack; synthesis probes start disabled

Generated output (`.perseus/cache/`, `live-context.md`) stays gitignored.
Conventions live in `standards/`; this directory is the host wiring those
conventions assume for agents.

See `templates/docs/ai/perseus-vault.md`.

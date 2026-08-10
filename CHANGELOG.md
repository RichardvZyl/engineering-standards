# Changelog

Notable changes to this repository. Changes under `standards/` are what downstream repos
actually receive, so they are listed first in each release and carry the `standards/VERSION`
they ship with.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning is
[Semantic Versioning](https://semver.org/spec/v2.0.0.html) applied to the standards set:

- **Major** — a rule is removed or reversed; downstream repos may now be non-compliant.
- **Minor** — a rule is added, or an existing one materially tightened.
- **Patch** — wording, links, typos; no change to what is required.

## [Unreleased]

### Added — `standards/` (v0.1.0, first synced content)

- `standards/VERSION` — starts at `0.1.0`.
- `standards/04-documentation-layout.md` — first standard in the set. Covers where planning
  documents live and, principally, **planning item identifiers**: one identifier per item,
  assigned by the document that defines it; identifiers are permanent and never renumbered;
  downstream documents cite the owning document's identifier rather than minting a parallel
  scheme; where two schemes already exist, the mapping is recorded in the owning document with
  each row marked confirmed, inferred or unknown, rather than resolved by assertion.

  Written in response to a real failure: a backlog acquired a second identifier scheme in a
  session handoff, and a later session could not tell which items the handoff's numbers referred
  to. The rules are shaped by that.

  This file also establishes the **read-only vendoring header** as the first instance of it.
  Every subsequent file under `standards/` opens with it verbatim.

### Added

- Repository scaffolding: `.editorconfig`, `.gitattributes`, `.gitignore`, MIT `LICENSE`.
- `scripts/Test-NoProprietaryLeak.ps1` — CI guard enforcing the convention/instance boundary.
  Deny list is stored as SHA-256 digests so the guard does not publish the names it excludes.
- `AGENTS.md` governing work on this repository.
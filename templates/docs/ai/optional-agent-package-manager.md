# Optional: Agent Package Manager (APM)

<!-- SEEDED ONCE from engineering-standards. Suggestion only. Delete this file
     if unused. Nothing in standards/ requires APM. -->

**Status:** optional / watch-list. Not a dependency. Not vendored.

[APM](https://github.com/microsoft/apm) is a dependency manager for agent
configuration: a manifest (`apm.yml`) that can install skills, prompts, plugins
and related primitives across agent hosts. Treat it as a **watch-list**, or as a
**side channel for third-party packages only**.

## Stance

- **Authored trees stay canonical.** An `AGENTS.md` you maintain, vendored
  convention packs, and a live skill/config tree already solve portability for
  many setups. APM does not replace those by existing.
- **Never two writers on the same paths.** If you already maintain a live
  canonical skill or config tree that machines consume through junctions,
  symlinks, or sync, do **not** also install APM as a second writer for those
  same paths. Junctioned trees, live-edited trees, synced trees, and
  hand-maintained skill directories are one source of truth; APM must not become
  another.
- **Third-party packages, if at all.** The only use that does not fight the
  tree is a side channel that installs *other people's* packages into a
  location the canonical tree does not own.
- **Cutover is not an add-on.** If APM ever becomes primary, that is a
  **deliberate migration** that retires the existing tree as writer. Running
  both in parallel is two sources of truth, and they will diverge.

## Dual source of truth

Two writers for one path is the failure this note exists to prevent. `apm
install` and a junctioned or synced tree both believe they own the files on
disk. The next install, the next sync, and the next hand edit will not agree,
and no PR will show the gap until something is already wrong.

Do not run APM as a parallel writer against a live canonical tree.

## Upstream

https://github.com/microsoft/apm

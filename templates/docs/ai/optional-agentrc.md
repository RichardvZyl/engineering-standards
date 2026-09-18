# Optional: agentrc

<!-- SEEDED ONCE from engineering-standards. Suggestion only. Delete this file
     if unused. Nothing in standards/ requires agentrc. -->

**Status:** optional / watch-list. Not a dependency. Not vendored.

[agentrc](https://github.com/microsoft/agentrc) measures a repository's
AI-readiness and can generate agent instruction files from the codebase. It
exists. It is not required.

## Stance

- **A different approach already works here.** An authored `AGENTS.md`,
  vendored convention packs, and a live canonical skill/config model already
  solve portability and readiness for many setups. Generating a second
  instruction file is not an improvement if it overwrites that.
- **Scores can mis-read this shape.** Readiness scores that assume per-repo
  generated agent configs will **mis-score** a setup that deliberately uses
  junctioned or globally linked skills, or upstream-vendored standards. The
  score is wrong, not the setup. Do not treat a low score as a mandate to
  generate files.
- **Do not overwrite authored pointers.** Prefer **not** letting generated
  output replace a carefully authored `AGENTS.md` or its `standards/`
  pointers. If you run a generator, send its output somewhere that is not
  those files.
- **Never two writers.** Same dual-source-of-truth caution as
  [APM](./optional-agent-package-manager.md): never run agentrc as a parallel
  writer against a live canonical tree. Junctioned trees, live-edited trees,
  synced trees, and hand-maintained skill directories stay the writer for
  those paths.

## Cutover

If agentrc ever becomes the producer of instruction files, that is a
**deliberate migration**, not an add-on alongside the existing tree. Retire
the previous writer in the same change.

## Upstream

https://github.com/microsoft/agentrc

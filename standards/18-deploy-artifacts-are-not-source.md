<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# 18 — Deploy artifacts are not source

Published runtime trees are **release snapshots**, not editable repositories. An agent that
edits TypeScript, tests, or policy *in place* under a deploy junction is working on the wrong
tree: the change is unversioned, unreviewable, and invisible to the next publish. Canonical
source lives under `${dev-root}/repositories` on a `fully-merged` line; what runs is a
built, content-addressed bundle.

This standard was earned when a loopback Node service deployed as a content-addressed
release was edited in place under its `current` junction. The publish had left a full
source-shaped tree (entry `.ts`, tests, editable knobs beside the code), so the runtime
folder looked like a project. It was not a git repository. Recovery required a rollback
copy of the pre-edit snapshot.

**Observed conventions this standard inherits and does not relitigate:** the vendored
read-only header on every file under `standards/` (this file); permanent numbered
`standards/NN-…` files with named section ids and settled **Rule.** /
**Decided. Do not relitigate.** wording ([`10.2`](./10-repository-and-worktree-layout.md));
`${dev-root}` path form with no absolute machine paths
([`09`](./09-durable-references.md), [`14.0`](./14-agent-working-directories-and-file-placement.md));
conventions here, instances in `AGENTS.md` ([`07`](./07-repo-layout.md)); ADR shape and
index discipline ([`05`](./05-decision-records.md)); VERSION / CHANGELOG / README table /
integrity scripts as the release surface for this set.

---

## 18.1 Deploy layout is not a repository

**Rule.** A published deploy tree must **not look like source**. It must not contain a
`src/` tree, a test tree, or unchecked-in `.ts` / `.tsx` (or equivalent) entrypoints that an
agent could treat as the project. Prefer **content-addressed release directories** plus a
`current` junction (or platform equivalent) that points at one immutable release folder.

**Decided. Do not relitigate.** The published tree is a runtime snapshot. The git repository
is elsewhere, under `${dev-root}/repositories/<owner>/<repo>/`, on a worktree beside
`root/` per [`10`](./10-repository-and-worktree-layout.md).

**Why.** A source-shaped deploy invites in-place edits. Those edits have no branch, no
review, and no merge — and the next publish silently overwrites or diverges from them.

**Practice.**

- Name release folders by content hash (or an equivalent content-addressed id).
- Point `current` at exactly one release. Do not keep a working copy of sources next to it.
- If a tree under the deploy root has a `.git` directory, that is a placement error — stop
  and relocate; do not "just commit there".

## 18.2 GENERATED banner and refuse-to-start

**Rule.** Every shipped code artifact begins with a **GENERATED / DO NOT EDIT** banner that
carries the **source repository identity and the commit SHA** it was built from. The
launcher **refuses to start** if the banner is missing **or** if a sibling source file
(`.ts` / `.tsx` or the language's equivalent) sits beside the runnable entrypoint.

**Decided. Do not relitigate.** Missing banner or sibling sources is a hard start failure,
not a warning.

**Why.** The banner is the agent-visible signal that the file is output. Refuse-to-start
makes editing the deploy tree fail *before* runtime drift accumulates.

**Practice.**

- Banner text is machine-checkable (fixed prefix the launcher greps).
- The check covers the entrypoint the launcher actually loads, not a distant `README`.
- Regenerating the artifact is the only allowed response to a refused start caused by a
  missing or stripped banner.

## 18.3 Read-only deploy tree

**Rule.** After publish, deploy **code** artifacts are **read-only** (ACL, filesystem
attribute, or equivalent) so an in-place edit **fails loudly**.

**Decided. Do not relitigate.** Silent success on write into a published code bundle is a
defect in the publish or the tree's permissions.

**Why.** Soft convention ("please do not edit") loses to the first agent that opens the
file. A permission error is unambiguous evidence that this is not the source tree.

## 18.4 Config vs code separation

**Rule.** Editable ops inputs — policy documents, peer-state, local launcher config, and
similar knobs — live **separate** from the immutable code bundle. Agents may treat
YAML / JSON (or equivalent) ops knobs as editable when that path is designated for ops.
**Code changes require rebuild and republish**; they are never patched into the running
bundle.

**Decided. Do not relitigate.** Mixing editable policy into the same folder as the
minified entrypoint is what made the incident's tree look like a project.

**Practice.**

- Ops inputs may sit beside the release under a clearly named config location owned by
  ops, or under a path documented in that service's `AGENTS.md` — never as unmarked
  siblings of the entrypoint that an agent will assume are source.
- If a change needs a compiler, bundler, or test run, it is a code change: work in the
  repository on `fully-merged` (or a branch that merges into it), then publish.

## 18.5 BUILD provenance

**Rule.** Every publish writes a `BUILD.json` next to the release with at least:

```json
{
  "repo": "<owner>/<name>",
  "branch": "fully-merged",
  "sha": "<full commit sha>",
  "builtAt": "<UTC timestamp>",
  "minify": true,
  "obfuscate": true
}
```

`branch` is `fully-merged` or the designated fully-merged **release ref**. Health or status
endpoints **must be able to echo** build identity (repo, branch, sha, builtAt) so operators
and agents can confirm what is running without opening the tree.

**Decided. Do not relitigate.** A running process that cannot name its build is unverifiable
evidence ([`11`](./11-evidence-and-verification.md)).

## 18.6 Publish-only path

**Rule.** There is **one** publish path. A publish script builds from `fully-merged` (or
the designated fully-merged release line), applies **minify** and **mild deterministic
obfuscation / name mangling**, writes the content-addressed hash folder, then flips
`current`. It **never** copies raw TypeScript (or equivalent) sources as the runnable
entrypoint.

**Decided. Do not relitigate.**

**Owner rulings that this section settles.**

- Source lives under `${dev-root}/repositories`. Nothing is **hosted or run as editable
  source** from the repositories tree — repositories hold git checkouts; runtimes consume
  published bundles.
- Build output may land anywhere a configured deploy/runtime root allows, but the output
  **must** be a release build (minified, mildly obfuscated) so an agent notices it is on
  **output**, not source. A configured deploy root is never a hardcoded drive letter
  ([`09`](./09-durable-references.md), [`14.0`](./14-agent-working-directories-and-file-placement.md)).
- Runnable builds come from a branch named **`fully-merged`**: the integration tip, ahead
  of feature branches, kept in sync with the remote. Feature work still happens in sibling
  worktrees per [`10`](./10-repository-and-worktree-layout.md); publish reads
  `fully-merged`, not a dirty WIP tree and not a live deploy tree.

**Why minify and mild obfuscation are required, not optional polish.** An untransformed
`.ts` tree under `current` is an engraved invitation to edit. Transformation is the
cheap signal that this folder is product, not a workspace.

## 18.7 Review checklist

- [ ] Deploy tree has no `src/`, no tests, and no sibling source entrypoints beside the
      runnable.
- [ ] Release dirs are content-addressed; `current` is a junction (or equivalent) to one
      of them.
- [ ] Every shipped code artifact carries the GENERATED banner with repo + sha.
- [ ] Launcher refuses start on missing banner or sibling sources.
- [ ] Deploy code artifacts are read-only after publish; a write attempt fails.
- [ ] Ops config is separate from the immutable code bundle.
- [ ] `BUILD.json` is present and health/status can echo build identity.
- [ ] Publish builds from `fully-merged` (or the designated release ref), minifies, applies
      mild deterministic obfuscation, writes the hash folder, flips `current`.
- [ ] No absolute machine paths appear in docs or scripts that describe the layout; paths
      use `${dev-root}` and configured deploy/runtime roots.
- [ ] Source edits happened under `${dev-root}/repositories/...` on a worktree, never under
      the deploy tree.

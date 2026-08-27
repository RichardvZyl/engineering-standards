<!-- SEEDED ONCE from engineering-standards. Move to .github/PULL_REQUEST_TEMPLATE.md
     in the consuming repo. Yours to edit — trim anything that does not apply to this project. -->

## What and why

<!-- What changed, and the why the diff cannot show. One or two sentences. -->

**Planning item:** <!-- identifier from the owning document, e.g. W5·E1. "None" is a valid
answer for a genuine one-off; a missing line is not. -->

## Review axes

Reviewers assess these separately and do not merge them into one verdict.

**Spec — does it do what was asked?**

<!-- Paste the acceptance criteria from the planning item. If there were none, write what
     "done" means, so the reviewer has something to check against rather than a recollection. -->

**Standards — does it follow the conventions?**

<!-- Note any deliberate departure and link the ADR. A departure that is not called out
     reads as a mistake and will be commented on as one. -->

## Data integrity

Delete any line that genuinely does not apply — but delete it deliberately, because these are
the questions that are expensive to answer after merge.

- [ ] Money handled as an exact decimal type; no floating-point anywhere near it
- [ ] Every query against tenant-scoped data carries a tenant predicate
- [ ] Isolation level is stated where it matters, not inherited by default
- [ ] Concurrent execution considered: what happens if this runs twice at once
- [ ] Retry-safe — a caller retrying after a timeout that arrived post-commit does not double-apply
- [ ] Nothing personal, secret, or cross-tenant is written to logs

## Database changes

- [ ] Not applicable

Otherwise:

- [ ] Migration is forward-only, idempotent, and tested at realistic data volume
- [ ] Destructive changes split into two deployments (stop writing, then remove)
- [ ] Backfill is batched and resumable; no single transaction over the whole table
- [ ] Index changes justified against a named access path
- [ ] Before/after execution plan attached for any changed hot query

<!-- Plan evidence goes here. "It looks faster" is not a measurement. -->

## Tests

- [ ] Build and tests green **before** the commit, not just before the merge
- [ ] Anything touching the database is tested against a real database, not an in-memory substitute
- [ ] A concurrency fix ships with a test that fails without the fix

## Blast radius

**Cost to reverse:** <!-- Reversible | Costly | One-way — and what makes it that. -->

<!-- Rate the shipped state, not the branch: a clean revert today is a backfill the moment this
     reaches production. Anything above Reversible needs an ADR — link it here.
     Scale: standards/05-decision-records.md. -->

<!-- What else touches this table, contract or queue. How this is rolled back if it is wrong,
     and when you would find out. "Revert the PR" is only true if there is no migration. -->

## Secrets

- [ ] No credential, key, token or connection detail is in this diff — including in fixtures,
      comments, and anything added then removed in an earlier commit on this branch
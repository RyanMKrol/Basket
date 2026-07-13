# custom/docs/LIMITATIONS.md — this project's trade-offs & limitations log

Customization overlay for `.harness/docs/LIMITATIONS.md`. **This is where your project's own
limitation/trade-off rows go** (golden rule 5): when a change introduces a trade-off, bottleneck, or known
limitation, add a row **here** — not in the pristine `docs/LIMITATIONS.md`, which is plugin-owned and
refreshed on upgrade. Harness upgrades never touch this file. (See `.harness/custom/CLAUDE.md`.)

Each row: what it is, *why* it was chosen, its **impact**, and *when to revisit*.

## Escalation ladder shortened to 3 rungs (2026-07-13)

**What:** `config/facets.json .tiers.ladder` went from the template's 5 rungs
(haiku → sonnet/low → sonnet/medium → sonnet/high → opus/high) to **3 rungs:
haiku/null → claude-sonnet-5/medium → claude-opus-4-8/medium**. Dropped
sonnet/low and sonnet/high; changed the top rung from opus/high to opus/medium.

**Why:** fail-faster. On this project each attempt is ~30-45 min wall-clock (slow
iOS-simulator CI run at multiple gates), and tasks that are genuinely stuck (e.g.
T019/T020, which broke the whole UI suite and exhausted the old ladder to
`blocked`) waste a lot of time and spend grinding through redundant middle tiers.
A stuck task now blocks after at most 3 × MAX_ATTEMPTS = 6 attempts (was 10).

**Impact:**
- Escalation jumps haiku → sonnet/medium → opus/medium; a task solvable only by
  sonnet/low now uses sonnet/medium (slightly more compute), and the hardest
  tasks top out at opus/**medium** rather than opus/high (less capability, less
  spend at the ceiling).
- The 5 historical sonnet/low outcome rows go inert (their tier is no longer on
  the ladder — `tidx()` re-matches by (model,effort) each run, so no corruption,
  just cosmetic `succeededRung` drift). Those (layer×work-type) cells revert to
  cold-start behavior. Haiku calibration (12 rows) is preserved.

**When to revisit:** if too many tasks block that opus/high would have solved (a
sign the top is now too weak), add an opus/high rung back; or if the jump from
sonnet/medium to opus is too costly, reinstate a sonnet/high middle rung. Change
via `/implementation-harness-update-ladder`, loop stopped.

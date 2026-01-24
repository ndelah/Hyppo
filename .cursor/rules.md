# Cursor Project Rules (QuietMap / Wardley Maps)

## Product constraints (non-negotiable)
- Offline-first: core functionality must work with no network.
- Privacy-by-default: do not add telemetry, tracking, or external calls unless explicitly requested.
- macOS app: optimize for macOS UX and performance.

## Delivery philosophy
- Optimize for shipping fast + correctness.
- Prefer Pareto solutions now; leave clear seams to improve later.
- Avoid overengineering: only introduce abstractions when they remove real duplication or risk.

## Architecture
- Use a layered architecture.
- Default: UI is thin; non-trivial logic should not live inside views.
- When uncertain where logic belongs, propose 2-3 placements and pick the simplest that keeps UI clean.

## Swift / SwiftUI conventions
- Prefer SwiftUI idioms (composable views, small view components).
- Keep view bodies readable: extract subviews/helpers when complexity grows.
- Avoid “clever” one-liners when clarity suffers.

## Quality & safety
- New non-trivial logic gets tests.
- Preserve existing behavior unless a change is explicitly intended.
- If a change may affect existing features or cause a breaking behavior change: STOP and ask first, describing:
  - what changes,
  - who it impacts,
  - safest alternative(s).

## Asking vs acting
Ask first when:
- requirements are unclear or ambiguous,
- behavior might change for existing features,
- change is large/risky (refactors, migrations, dependency upgrades, sweeping renames),
- deleting or restructuring files/modules.

You may proceed without asking when:
- the change is small, local, and low-risk,
- it clearly does not alter existing behavior,
- you can state assumptions and they are reversible.

## Git commits
Use Conventional Commits:
<type>[optional scope][!]: <short summary>

[optional body]

[optional footer(s)]

Style:
feat – a new feature (user-visible)
fix – a bug fix
docs – documentation only
style – formatting, missing semicolons, whitespace (no logic change)
refactor – code change that neither fixes a bug nor adds a feature
perf – performance improvement
test – adding or fixing tests
build – build system or dependencies (npm, gradle, etc.)
ci – CI configuration (GitHub Actions, GitLab CI)
chore – maintenance tasks, tooling, no production code change
revert – reverts a previous commit

examples:

feat(auth): add refresh token rotation
fix(ui): prevent sidebar overflow on small screens



Rules:
- Imperative mood in summary.
- Keep summary concise and specific.
- Use scope when it helps navigation (e.g. map, canvas, export, persistence, ui).
- Add body when change isn’t obvious; include rationale/trade-offs.
- Use ! for breaking changes, and explain in body/footer.

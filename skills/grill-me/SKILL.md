---
name: grill-me
description: Clarifying-question discipline for spec and plan work. Use when an agent is about to commit to a spec or plan that contains assumptions the user hasn't actually confirmed. Surfaces those assumptions as questions before they become drift.
---

# grill-me

Most spec drift comes from agents inferring missing context instead of asking. This skill enforces the opposite: surface every load-bearing assumption as a numbered question, **before** writing the final artifact.

## When to apply

- Spec-builder is consolidating a SPEC.md and notices a field the ticket doesn't actually specify
- Planner is about to write PLAN.md and hits a fork in the road (library choice, layering decision, edge-case behavior)
- Implementer notices the plan doesn't cover a case that affects the code shape (and chose to stop and surface, per its rules)

## How to apply

1. Write a numbered list of questions. Each one names the assumption being made and asks the user to confirm or correct.
2. Be specific. "Should we use Postgres?" is bad. "The plan assumes Postgres because the existing repo already uses Prisma + Postgres in `lib/db.ts:14`. Is that correct, or should this feature use a different store?" is good.
3. Group questions by topic if there are more than five. Five is the soft cap — more than that means the spec wasn't ready for planning.
4. After each question, propose a default answer in italics: *Default: yes — confirm or override.* This lets the user accept the default with a single "yes" instead of typing five answers.
5. Stop. Do not write the artifact until the user replies.

## Anti-patterns

- Don't ask philosophical questions ("what is the goal here?"). The ticket has a goal — read it.
- Don't ask questions whose answers are obviously in the codebase. Read the code first.
- Don't ask more than the user can answer in 60 seconds. If the list is long, the spec isn't ready.

---
name: architectural-decision-records
description: Use when documenting, drafting, reviewing, or updating architectural decisions, ADRs, decision logs, tradeoffs, rationale, consequences, alternatives, or architecture decision history.
---

# Architectural Decision Records

## Overview

An Architectural Decision Record captures one architecturally significant decision, its rationale, tradeoffs, and consequences. Optimize for future readers reconstructing decision history.

This pipeline locks the format to **MADR-minimal** in `docs/adr/<nnnn>-<kebab-slug>.md` with zero-padded four-digit numbering (`0001`, `0002`, ...). One decision per file. See `templates/madr-minimal.md` for the canonical shape.

## When to Use

Use when creating, updating, reviewing, or explaining an ADR, architecture decision, decision log, tradeoff analysis, rationale, consequences, alternatives, or status.

Do not use ADRs for transient implementation details, meeting notes, or insignificant decisions. If significance is unclear, ask what future maintainers will need to know.

## Workflow

1. Identify the single decision. Split multiple decisions into multiple ADRs.
2. Find the next number: read `docs/adr/`, take the highest existing number, add one, zero-pad to four digits.
3. Use the template at `templates/madr-minimal.md`.
4. Capture known facts only: context, requirements, constraints, options, rationale, decision makers, consequences.
5. If facts are missing, mark them as `Unknown` or ask a focused question; do not invent context, options, or quality attributes.
6. Write honest consequences: benefits, downsides, follow-up.
7. Preserve history: supersede old accepted ADRs; do not rewrite them away.

## Status Values

| Status | Use when |
| --- | --- |
| Proposed | Under review |
| Accepted | Team committed |
| Deprecated | Historically relevant but no longer recommended |
| Superseded | Replaced by another ADR; link it |

## Review Checklist

- One decision, not a bundle
- Significant: affects structure, quality attributes, constraints, or evolution
- Context explains why it existed
- Rejected options/tradeoffs are explicit
- Rationale is tied to requirements, not preference
- Downsides and follow-up work are recorded
- Status is clear
- Unknowns are marked, not invented

## Example

```markdown
# 0012. Use PostgreSQL for Orders

## Context and Problem Statement

Orders need relational constraints, consistency, and reporting joins. The team operates PostgreSQL well.

## Considered Options

- PostgreSQL: integrity, SQL reporting, familiar operations; migrations required.
- MongoDB: flexible schema; weaker fit for consistency and joins.

## Decision Outcome

Chosen option: "PostgreSQL", because consistency, joins, and operational familiarity matter more than schema flexibility.

### Consequences

- Good, because integrity and reporting align with needs.
- Bad, because schema changes need migrations.
- Follow-up: define migration practice.
```

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Several decisions in one ADR | Split them. |
| Sales pitch | Include rejected options and negative consequences. |
| Invented context | Mark unknowns or ask. |
| Treating status as decoration | Use status to show lifecycle and link superseding ADRs. |
| Rewriting history | Keep old ADR; create/link superseding ADR. |
| Omitting alternatives under pressure | Include at least the rejected option and why it lost. |
| Non-sequential or non-zero-padded numbers | Always find the highest existing number, add one, zero-pad to four digits. |

## Sources

adr.github.io: home, ADR templates, AD practices. MADR template: https://github.com/adr/madr.

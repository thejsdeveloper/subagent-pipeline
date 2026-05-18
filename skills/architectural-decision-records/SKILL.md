---
name: architectural-decision-records
description: ADR template, numbering, and lifecycle. MADR-minimal format, zero-padded four-digit numbering, one decision per file in docs/adr/. Use when drafting or accepting an ADR.
---

# architectural-decision-records

ADRs record the why behind architectural choices so future contributors don't have to guess. The pipeline standardizes on **MADR-minimal**: one file per decision, short, in Markdown.

## Where ADRs live

`docs/adr/<nnnn>-<kebab-slug>.md`

Numbering is zero-padded to four digits: `0001`, `0002`, … `0042`. Always monotonic. Never reuse a number. Always find the highest existing number and add one.

## Template

```markdown
# <nnnn>. <Title>

Date: <YYYY-MM-DD>
Status: <Proposed | Accepted | Deprecated | Superseded by ADR-<n>>

## Context
<2-4 sentences: the problem, the constraints, what's at stake. Not the solution.>

## Decision
<1-2 paragraphs: what we're going to do. Active voice. Concrete.>

## Consequences
<both positive and negative: what we get, what we give up, what we'll regret if this is wrong>

## Alternatives considered
- <alt 1> — why not
- <alt 2> — why not
```

## Lifecycle

1. **Proposed** — drafted by the planner or architect, not yet accepted. The user reviews.
2. **Accepted** — the user has agreed. The ADR is now a rule that the reviewer enforces against future code.
3. **Deprecated** — the decision no longer applies but is kept for history.
4. **Superseded by ADR-<n>** — a new ADR has replaced this one. Do not edit the original; create the new one.

## Rules

- One decision per file. If you find yourself writing "and we'll also decide X", split into two ADRs.
- Keep ADRs short. If the body is longer than one screen, it's probably two decisions or it has too much narrative.
- The first ADR (`0001-record-architecture-decisions.md`) is the meta-ADR that says "we record decisions in this format, in this folder, with this numbering."
- Once Accepted, the body is frozen. Update status only. If the decision changes, write a new ADR.

## Meta-ADR template (the seed file)

```markdown
# 0001. Record architecture decisions

Date: <YYYY-MM-DD>
Status: Accepted

## Context
This codebase needs a lightweight way to record architectural decisions so future contributors can understand why the system looks the way it does, not just what it does.

## Decision
We will record architectural decisions in `docs/adr/<nnnn>-<kebab-slug>.md`, using the MADR-minimal template. Numbering is zero-padded to four digits, monotonic, never reused. One decision per file.

## Consequences
Positive: searchable history of why we chose X over Y. New contributors get context fast.
Negative: requires discipline — decisions made without an ADR are invisible.

## Alternatives considered
- No ADRs (institutional memory only) — fails when people leave.
- Long architecture doc with embedded decisions — decisions get buried; status hard to track.
- Full MADR (with detailed pros/cons matrices) — too much overhead for most decisions.
```

## Anti-patterns

- Backfilling ADRs for decisions made years ago "because we should have one". Only record live decisions.
- Editing an Accepted ADR. Create a new one that supersedes it.
- ADRs that read like blog posts. Keep them factual and short.

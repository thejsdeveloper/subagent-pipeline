# 0001. Record architecture decisions

Date: <YYYY-MM-DD>
Status: Accepted

## Context
This codebase needs a lightweight way to record architectural decisions so future contributors can understand why the system looks the way it does, not just what it does.

## Decision
We will record architectural decisions in `docs/adr/<nnnn>-<kebab-slug>.md`, using the MADR-minimal template. Numbering is zero-padded to four digits, monotonic, never reused. One decision per file. See the `architectural-decision-records` skill for the template.

## Consequences
Positive: searchable history of why we chose X over Y. New contributors get context fast. The reviewer agent can enforce Accepted decisions against incoming diffs.

Negative: requires discipline — decisions made without an ADR are invisible. Mitigated by the planner agent: when a plan introduces a new layer, swaps a major dependency, or contradicts an existing ADR, the planner drafts a Proposed ADR alongside `PLAN.md`.

## Alternatives considered
- No ADRs (institutional memory only) — fails when people leave the team.
- Long architecture doc with embedded decisions — decisions get buried; status hard to track.
- Full MADR (with detailed pros/cons matrices) — too much overhead for most decisions.

# AGENTS.md — subagent-pipeline

> **This is the meta-AGENTS.md for the pipeline repo itself.** When you install the pipeline into your project (`./install.sh --cursor` etc.), a project-level `AGENTS.md` is created in your repo by `/onboarding`. That one describes *your* project. This one describes *the pipeline*.

## What this project is

A drop-in, multi-agent AI development pipeline for brownfield and greenfield codebases. Seven agents, two phases, one stop for human review. Cross-compatible with Cursor, Claude Code, and Codex.

## The seven agents

| Agent | Phase | Writes |
|---|---|---|
| `/spec-builder` | Phase 1 | `agent-run/<id>/SPEC.md` |
| `/planner` | Phase 1 | `agent-run/<id>/PLAN.md`, optionally `docs/adr/<n>-<slug>.md` (Proposed) |
| `/implementer` | Phase 2 | source code + `agent-run/<id>/IMPLEMENTATION_NOTES.md` |
| `/reviewer` | Phase 2 | `agent-run/<id>/REVIEW.md` |
| `/qa` | Phase 2 | tests + `agent-run/<id>/QA_REPORT.md` |
| `/onboarding` | One-time | `AGENTS.md`, `docs/CONVENTIONS.md`, `docs/ARCHITECTURE.md`, `docs/adr/0001-*.md` |
| `/architect` | On-demand | `docs/ARCHITECTURE.md`, new ADRs, `docs/diagrams/*.md` |

## Read/write matrix (prompt-level constraints)

| Agent | May write |
|---|---|
| spec-builder | `agent-run/<id>/SPEC.md` |
| planner | `agent-run/<id>/PLAN.md`, optionally a new `docs/adr/<n>-<slug>.md` in Proposed |
| implementer | source code, tests, `agent-run/<id>/IMPLEMENTATION_NOTES.md` — **never `git add` / `commit` / `push` / `stash` / `checkout`** |
| reviewer | `agent-run/<id>/REVIEW.md` only |
| qa | `agent-run/<id>/QA_REPORT.md`, tests |
| onboarding | `AGENTS.md` (root), `docs/CONVENTIONS.md`, `docs/ARCHITECTURE.md`, `docs/adr/0001-*.md` |
| architect | `docs/ARCHITECTURE.md`, `docs/adr/<n>-<slug>.md`, `docs/diagrams/<slug>.md` |

Read access is unrestricted. **Write constraints are enforced at the prompt level**, not the tool level — the runtime allows broader access, but each agent self-limits.

## The orchestrator

`/feature-pipeline` is a two-phase wrapper that chains the agents around one mandatory stop:

- **Phase 1 (plan):** spec-builder → planner → STOP at `PLAN.md` for user review
- **Phase 2 (build):** implementer → reviewer → qa (no pause)

The pause between planner and implementer is load-bearing. Skipping it loses the human-in-the-loop guarantee.

Phase 1 takes either a Jira `ticket-id` alone, a `Task` alone (orchestrator derives a `<date>-<slug>` ticket-id), or both. Phase 2 takes a `Run directory` only.

## The convention chain

The pipeline reads these files in order when planning, implementing, reviewing, and QA-ing:

1. `AGENTS.md` (project root) — overview, stack, entry points
2. `docs/CONVENTIONS.md` — language, linter, tests, branching
3. `docs/ARCHITECTURE.md` — folder map, layering rules, external deps
4. `openapi.yaml` (optional, backend / full-stack only) — endpoint shapes
5. `docs/adr/*.md` — accepted architectural decisions

If any of #1–#3 is missing, the agents will tell the user to run `/onboarding` first.

## The skills

Five reusable skills in `skills/`:

- `grill-me` — clarifying-question discipline
- `gherkin-authoring` — GIVEN/WHEN/THEN acceptance scenarios
- `architecture-diagrams` — C4 + Mermaid, locked-in
- `architectural-decision-records` — MADR-minimal, zero-padded numbering
- `brownfield-onboarding` — discovery sequence for repos with no docs

Skills are referenced by name in agent prompts. Claude Code auto-loads them by description; Cursor and Codex read them as files when referenced.

## Repo layout

```
subagent-pipeline/
├── agents/                    # Universal agent definitions (one folder, all providers)
├── commands/                  # Slash commands (currently: feature-pipeline)
├── skills/                    # Reusable skill behaviours
├── docs/                      # Template docs that ship to user repos via install.sh
│   ├── CONVENTIONS.md         # template
│   ├── ARCHITECTURE.md        # template
│   ├── adr/                   # meta-ADR + project ADRs
│   └── diagrams/              # Mermaid diagrams in Markdown
├── AGENTS.md                  # this file (meta — describes the pipeline)
├── install.sh                 # drop-in installer (--cursor | --claude | --codex)
└── README.md
```

`agent-run/<ticket-id>/` is created per feature in the **user's** project, not in this repo.

## How to install into a project

From the user's project root:

```bash
/path/to/subagent-pipeline/install.sh --cursor    # for Cursor
/path/to/subagent-pipeline/install.sh --claude    # for Claude Code
/path/to/subagent-pipeline/install.sh --codex     # for Codex
```

This copies agents, commands, skills to the provider-specific path, and template docs to `docs/`. Run `/onboarding` once in the project to fill in the docs.

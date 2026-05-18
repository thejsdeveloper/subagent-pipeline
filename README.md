# subagent-pipeline

A drop-in multi-agent AI development pipeline for **brownfield and greenfield codebases**. Seven agents, two phases, one stop for human review. Cross-compatible with **Cursor**, **Claude Code**, and **Codex** — one folder per concern (agents, commands, skills), one installer.

```
SPEC ──► PLAN ──► [you review] ──► CODE ──► REVIEW ──► QA
```

The pause between PLAN and CODE is mandatory. Skipping it loses the human-in-the-loop guarantee.

---

## Why

Most "AI codes the whole feature" workflows quietly break adversarial separation: the same context that wrote the plan also writes the code, and the same context that wrote the code also reviews it. Bugs slip through because no one is reading the diff cold.

This pipeline enforces separation by spawning each role as a fresh subagent context. The reviewer cannot read the planner's notes. The QA agent cannot read the implementer's rationalisations. Code is judged against the spec, not against the implementer's story about the spec.

---

## What you get

### Seven agents

| Agent | Role | Writes |
|---|---|---|
| `/spec-builder` | Pull a Jira ticket + linked Confluence pages, consolidate into a SPEC | `agent-run/<id>/SPEC.md` |
| `/planner` | Read SPEC + convention chain, propose a technical plan | `agent-run/<id>/PLAN.md` (+ optional ADR draft) |
| `/implementer` | Execute the approved plan, write code + tests | source code + `IMPLEMENTATION_NOTES.md` |
| `/reviewer` | Cold-eyes adversarial review of the diff | `agent-run/<id>/REVIEW.md` |
| `/qa` | Tests + manual verification checklist | tests + `agent-run/<id>/QA_REPORT.md` |
| `/onboarding` | First-run: read the codebase, generate AGENTS.md + docs scaffolding | `AGENTS.md`, `docs/*` |
| `/architect` | On-demand: update architecture docs, draft ADRs, generate diagrams | `docs/ARCHITECTURE.md`, `docs/adr/*`, `docs/diagrams/*` |

### Two phases (optional orchestrator)

`/feature-pipeline` chains the build phase agents with one mandatory stop:

- **Phase 1 (plan):** spec-builder → planner → STOP for user review of `PLAN.md`
- **Phase 2 (build):** implementer → reviewer → qa (no pause)

You can also invoke each agent manually if you want full control.

### Five skills

Reusable behaviours loaded by name from `skills/`:

- `grill-me` — clarifying-question discipline before writing a spec or plan
- `gherkin-authoring` — GIVEN/WHEN/THEN acceptance scenarios
- `architecture-diagrams` — locked-in C4 + Mermaid (no choice fatigue)
- `architectural-decision-records` — MADR-minimal, zero-padded numbering
- `brownfield-onboarding` — discovery sequence for repos with no docs

### Opinionated docs scaffolding

```
docs/
├── CONVENTIONS.md          # language, linter, tests, branching
├── ARCHITECTURE.md         # folder map, layering rules, external deps
├── adr/
│   └── 0001-record-architecture-decisions.md
└── diagrams/               # Mermaid in Markdown
```

The pipeline reads this **convention chain** when planning and reviewing. Filled in by `/onboarding` on first run.

---

## Install

From your project's root:

```bash
git clone https://github.com/thejsdeveloper/subagent-pipeline /tmp/subagent-pipeline

# pick one:
/tmp/subagent-pipeline/install.sh --cursor
/tmp/subagent-pipeline/install.sh --claude
/tmp/subagent-pipeline/install.sh --codex
```

This copies `agents/`, `commands/`, `skills/` into `.cursor/` (or `.claude/`, or `.codex/`), seeds `AGENTS.md` and `docs/` if they don't exist, and creates `agent-run/` for per-feature artifacts.

After install:

```
your-project/
├── .cursor/                   # or .claude/ or .codex/
│   ├── agents/
│   ├── commands/
│   └── skills/
├── docs/
│   ├── CONVENTIONS.md
│   ├── ARCHITECTURE.md
│   ├── adr/
│   └── diagrams/
├── agent-run/                 # populated per-feature
├── AGENTS.md
└── (your code)
```

Then in your IDE: invoke `/onboarding` once. The agent reads your codebase and fills in `AGENTS.md`, `docs/CONVENTIONS.md`, and `docs/ARCHITECTURE.md` based on what it finds. Edit the result to your taste. Done.

---

## Usage

### First feature

```
/feature-pipeline
Task: Add a tooltip to the Save button explaining unsaved changes
ticket-id: PROJ-1234
```

The orchestrator pulls the ticket, drafts a SPEC, then drafts a PLAN, then **stops** so you can review `agent-run/PROJ-1234/PLAN.md`. Edit or push back. When the plan is right:

```
/feature-pipeline
Run directory: agent-run/PROJ-1234/
```

This runs implementer → reviewer → qa back-to-back. You commit the diff manually.

### Manual control

If you'd rather drive each step yourself:

```
/spec-builder PROJ-1234
/planner for ticket PROJ-1234     ← review PLAN.md
/implementer for ticket PROJ-1234
/reviewer for ticket PROJ-1234
/qa for ticket PROJ-1234
```

Each in a separate chat input. Separate inputs are what guarantee fresh context per agent.

---

## Read/write matrix (prompt-level constraints)

| Agent | May write |
|---|---|
| spec-builder | `agent-run/<id>/SPEC.md` |
| planner | `agent-run/<id>/PLAN.md` (+ optional Proposed ADR in `docs/adr/`) |
| implementer | source code, tests, `agent-run/<id>/IMPLEMENTATION_NOTES.md` — **never `git add` / `commit` / `push`** |
| reviewer | `agent-run/<id>/REVIEW.md` only |
| qa | `agent-run/<id>/QA_REPORT.md`, tests |
| onboarding | `AGENTS.md`, `docs/CONVENTIONS.md`, `docs/ARCHITECTURE.md`, `docs/adr/0001-*.md` |
| architect | `docs/ARCHITECTURE.md`, new ADRs, `docs/diagrams/*` |

Write constraints are enforced **at the prompt level**, not the tool level. The runtime allows broader access, but each agent self-limits. This is by design — tool-level read-only previously blocked legitimate writes (the planner couldn't write `PLAN.md`).

---

## Frontmatter (combined, works across all three providers)

Every agent uses a single universal frontmatter:

```yaml
---
name: planner
description: ...
model: inherit
readonly: false
tools: Read, Write, Grep, Glob
---
```

- **Cursor** and **Codex** read `readonly:` and ignore `tools:`
- **Claude Code** reads `tools:` and ignores `readonly:`

One file, three providers. The agents themselves are identical across CLIs.

---

## Repo layout

```
subagent-pipeline/
├── agents/                    # 7 agent definitions
├── commands/                  # 1 slash command (feature-pipeline)
├── skills/                    # 5 reusable skills
├── docs/                      # template scaffolding for user projects
│   ├── CONVENTIONS.md
│   ├── ARCHITECTURE.md
│   ├── adr/0001-*.md
│   └── diagrams/
├── AGENTS.md                  # meta — describes this pipeline
├── install.sh                 # --cursor | --claude | --codex
├── LICENSE                    # MIT
├── CREDITS.md                 # attribution for skills and concepts
└── README.md
```

---

## Versioning

- `v1` — per-provider folders (`cursor/`, `claude/`, `codex/`). Tagged in git.
- `v2` (current) — single `agents/` + `commands/` + `skills/`, `install.sh`, brownfield-onboarding workflow, ADR + diagram conventions.

To roll back: `git checkout v1`.

---

## Credits

This pipeline borrows skill bodies and structure from open work by [Matt Pocock](https://github.com/mattpocock/skills) and [intent-driven-dev](https://github.com/intent-driven-dev/intent-driven-template). Full attribution in [CREDITS.md](CREDITS.md).

## License

MIT.

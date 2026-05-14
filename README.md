# subagent-pipeline

A five-subagent dev pipeline you can drop into any project for spec-builder → planner → implementer → reviewer → qa orchestration with structured handoffs. Designed for **manual orchestration** — you fire each subagent as a separate slash command — because that's the only way to guarantee fresh contexts and adversarial separation per step. Works with Cursor, Claude Code, and Codex via their native subagent paths.

## The five agents

| Agent | Role | Write constraint |
|---|---|---|
| `spec-builder` | Fetches a Jira ticket via MCP, consolidates the spec from linked Confluence pages, writes `SPEC.md`. Stops. | Writes only `agent-run/<id>/SPEC.md` |
| `planner` | Reads `SPEC.md` + the convention chain, produces a technical `PLAN.md` (approach, file changes, risks). Stops for user review. | **Prompt-constrained:** writes only `agent-run/<id>/PLAN.md`. Cannot touch source. |
| `implementer` | Reads the approved `PLAN.md` + `SPEC.md` + convention chain. Executes the plan. Writes `IMPLEMENTATION_NOTES.md`. | Full source read/write |
| `reviewer` | Reads the diff cold against `SPEC.md` + conventions. Does NOT read PLAN or NOTES (cold review). Outputs BLOCKING / ADVISORY / GOOD. | **Prompt-constrained:** writes only `agent-run/<id>/REVIEW.md`. Cannot touch source. Bash limited to read-only commands. |
| `qa` | Reads `SPEC.md` + `REVIEW.md` (BLOCKING section) + diff. Does NOT read PLAN or NOTES. Writes tests + manual checklist to `QA_REPORT.md`. | Full read/write (needs to add test files) |

The reviewer's read-only constraint is the heart of the pattern. Adversarial separation isn't a prompt instruction; it's a tool-level guarantee.

**Note:** this repo does NOT include an "orchestrator" agent that runs the four in sequence. That's an explicit design choice — see [Why manual orchestration](#why-manual-orchestration) below.

## Why per-provider folders

The same agents work across Cursor, Claude Code, and Codex, but the frontmatter syntax for tool restriction differs:

- **Cursor:** `readonly: true` to block writes
- **Claude Code:** `tools:` allowlist (e.g., `tools: Read, Grep, Glob, Bash`)
- **Codex:** mirrors Cursor for now (the spec is in flux)

Each provider folder ships agents in the right frontmatter format. The agent bodies are identical across providers.

## Repo layout

```
subagent-pipeline/
├── cursor/
│   ├── agents/          # 5 subagents → .cursor/agents/
│   └── commands/        # orchestrator → .cursor/agents/ (Cursor treats commands as subagents)
├── claude/
│   ├── agents/          # 5 subagents → .claude/agents/
│   └── commands/        # orchestrator → .claude/commands/ (Claude Code has a separate path)
└── codex/
    ├── agents/          # 5 subagents → .codex/agents/
    └── commands/        # orchestrator → .codex/agents/ (Codex treats commands as agents)
```

The split between `agents/` and `commands/` is conceptual: agents are reusable subagents (`/spec-builder`, `/planner`, `/implementer`, `/reviewer`, `/qa`); commands are user-facing orchestrators that compose multiple agents (`/feature-pipeline`). For Claude Code, the split also matches real destination directories. For Cursor and Codex, both end up in the same `.{tool}/agents/` folder.

## Install

Pick your editor and run the matching commands.

### Cursor

Both subagents and commands live in `.cursor/agents/`:

```bash
cd /path/to/your/project
mkdir -p .cursor/agents
cp /path/to/subagent-pipeline/cursor/agents/*.md    .cursor/agents/
cp /path/to/subagent-pipeline/cursor/commands/*.md  .cursor/agents/
```

Or symlink the contents (works on macOS / Linux):

```bash
mkdir -p .cursor/agents
ln -s /path/to/subagent-pipeline/cursor/agents/*.md    .cursor/agents/
ln -s /path/to/subagent-pipeline/cursor/commands/*.md  .cursor/agents/
```

### Claude Code

Subagents and commands go to separate directories:

```bash
cd /path/to/your/project
mkdir -p .claude/agents .claude/commands
cp /path/to/subagent-pipeline/claude/agents/*.md    .claude/agents/
cp /path/to/subagent-pipeline/claude/commands/*.md  .claude/commands/
```

Or symlink:

```bash
mkdir -p .claude
ln -s /path/to/subagent-pipeline/claude/agents    .claude/agents
ln -s /path/to/subagent-pipeline/claude/commands  .claude/commands
```

### Codex

Same shape as Cursor — both go to `.codex/agents/`:

```bash
cd /path/to/your/project
mkdir -p .codex/agents
cp /path/to/subagent-pipeline/codex/agents/*.md    .codex/agents/
cp /path/to/subagent-pipeline/codex/commands/*.md  .codex/agents/
```

## The convention chain

Every project that uses these agents should have three files at the repo root:

- **CONVENTIONS.md** — naming, error patterns, testing style, idioms
- **ARCHITECTURE.md** — folder layout, layer rules, hard dependency rules
- **openapi.yaml** (or `schema.prisma`, or SQL DDL) — the canonical contract

The implementer reads all three before writing any code. The reviewer checks against them. The qa agent runs the project's testing convention.

If you don't have these files yet, write tiny versions — even 30 lines beats nothing. Iterate as the agents reveal what's ambiguous. (Tip: ask `/implementer` to draft the three files by introspecting the existing codebase, then human-review the output.)

## Usage

The pipeline is **manually orchestrated** — you fire each subagent as a separate slash command. This is intentional (see [Why manual orchestration](#why-manual-orchestration)).

### Full Jira-integrated flow

In your editor's main chat, run these **as five separate prompts**:

```
1. /spec-builder JIRA-1234
2. /planner for ticket JIRA-1234       ← review and approve PLAN.md before continuing
3. /implementer for ticket JIRA-1234
4. /reviewer for ticket JIRA-1234
5. /qa for ticket JIRA-1234
```

Each command must be a separate user input. Do not chain them in one message. Each fresh slash command is what guarantees a fresh subagent context.

**The course-correction beat is at step 2.** After `/planner` produces `PLAN.md`, you read it. If anything's wrong, tell the planner what to change (it iterates), or edit `PLAN.md` directly in your IDE. The implementer doesn't run until you're satisfied with the plan.

### Without Jira

If you don't have a ticket, skip `spec-builder` and start with `planner`. Use a kebab-case slug as the run ID:

```
1. /planner Build the POST /refunds endpoint per openapi.yaml. Use slug add-refunds-endpoint.   ← writes PLAN.md, review it
2. /implementer for slug add-refunds-endpoint
3. /reviewer for slug add-refunds-endpoint
4. /qa for slug add-refunds-endpoint
```

## What it produces

The pipeline writes all artifacts to `agent-run/<ticket-id>/`:

```
agent-run/
└── PROJ-1234/
    ├── SPEC.md                  ← spec-builder
    ├── PLAN.md                  ← planner (you review this)
    ├── IMPLEMENTATION_NOTES.md  ← implementer
    ├── REVIEW.md                ← reviewer
    └── QA_REPORT.md             ← qa
```

For runs without a ticket, the slug is used instead (e.g., `agent-run/2026-05-13-add-tooltip/`).

Each artifact is the structured handoff to the next subagent. They also serve as a per-feature audit trail you can keep, archive, or discard at PR time. See [Workflow conventions](#workflow-conventions) for how to handle them.

## Orchestrator command — `/feature-pipeline`

The five-step manual flow above gives you maximum control but takes five separate prompts. The optional `/feature-pipeline` command chains the steps you don't need to intervene between, with a single hard stop at PLAN.md review.

### What chains, what stops

| Boundary | Chained? | Why |
|---|---|---|
| `spec-builder` → `planner` | ✅ chained (auto-stop if SPEC has open questions) | Planner needs SPEC; if SPEC is clean, no user input needed between them |
| `planner` → `implementer` | ❌ **HARD STOP** | This is the whole point of `/planner` — you review and approve PLAN.md before any code is written |
| `implementer` → `reviewer` → `qa` | ✅ chained | Reviewer reads cold; QA reads REVIEW.md + diff. No user input needed between any of them. |

### Two-phase usage

**Phase 1 — plan only** (stops at PLAN.md for your review):

```
/feature-pipeline
Task: Add a POST /refunds endpoint with idempotency
ticket-id: PROJ-1234
```

The orchestrator runs `/spec-builder` (if `ticket-id` is a Jira ID) then `/planner`, then stops. You read `agent-run/PROJ-1234/PLAN.md`. Edit it, or tell the planner to iterate. When the plan is final:

**Phase 2 — implement + verify** (no pause):

```
/feature-pipeline
Run directory: agent-run/PROJ-1234/
```

The orchestrator runs `/implementer` → `/reviewer` → `/qa` back-to-back. No stops. Final summary is printed.

### Phase detection logic

The orchestrator auto-detects which phase to run:

- **Run directory provided AND `PLAN.md` exists there** → Phase 2
- **Task + ticket-id provided, no Run directory (or no PLAN.md)** → Phase 1
- **Both filled, PLAN.md exists** → Phase 2 (prefer)
- **Both filled, PLAN.md missing** → Phase 1

### When to prefer the manual five-step flow

Use the manual flow (no orchestrator) when:

- You want to inspect each artifact before the next step runs
- You're debugging the pipeline itself
- A subagent has been making poor judgements and you want fine-grained control

Use the orchestrator when:

- The plan looks solid and you trust the implementer + reviewer + qa to chain
- You want fewer keystrokes per ticket

## Read matrix

Who reads what after the pipeline matures. **R** = reads, **W** = writes.

| File / Source | spec-builder | planner | implementer | reviewer | qa |
|---|:---:|:---:|:---:|:---:|:---:|
| Jira ticket (MCP) | **R** | — | — | — | — |
| Confluence pages (MCP) | **R** | — | — | — | — |
| `agent-run/<id>/SPEC.md` | **W** | R | R | R | R |
| `agent-run/<id>/PLAN.md` | — | **W** | R | — | — |
| `agent-run/<id>/IMPLEMENTATION_NOTES.md` | — | — | **W** | — | — |
| `agent-run/<id>/REVIEW.md` | — | — | — | **W** | R (BLOCKING only) |
| `agent-run/<id>/QA_REPORT.md` | — | — | — | — | **W** |
| `CONVENTIONS.md` (root) | — | R | R | R | R |
| `ARCHITECTURE.md` (root) | — | R | R | R | — |
| `openapi.yaml` (root) | — | R | R | R | — |
| Source files | — | R | R + W | R | R + W tests |
| `git diff main...HEAD` | — | — | — | R | R |

> **On the `planner` and `reviewer` rows:** the `R` for source files is the *intended* operational state, enforced at the prompt level only. Both agents technically have write access to source via the runtime; they refuse to use it because their prompts forbid it. Same for the implementer's restriction on running `git add` / `git commit` — the runtime allows those commands, the prompt forbids them. See [On the write constraint for planner and reviewer](#on-the-write-constraint-for-planner-and-reviewer) for the reasoning and trade-off.

### Two design choices in this matrix

1. **The reviewer is genuinely cold.** It does NOT read `PLAN.md` or `IMPLEMENTATION_NOTES.md`. Reading the implementer's plan or post-hoc notes would anchor the reviewer to the implementer's framing — that's the opposite of adversarial separation. The reviewer reads only the spec, the conventions, the code at HEAD, and the diff. It judges code-against-spec, not code-against-stated-intent.

2. **QA acts like real-world QA.** It does NOT read `PLAN.md` or `IMPLEMENTATION_NOTES.md`. Real QA doesn't get the engineering plan or the engineer's diary; they get the spec and the changes. The one automation-specific exception: QA reads `REVIEW.md`'s BLOCKING section so it can write regression tests for the bugs the reviewer caught. That cross-pollination is something real-life QA can't do (they have no access to the reviewer's notes), and it's a real strength of the pipeline.

### Where does plan-drift detection go, then?

It's your job at PR time. After the implementer finishes, you have `PLAN.md` (which you approved) and the diff. Open both side-by-side. If the implementer departed from the plan, you catch it — and you're the right person to, because you approved the plan. The reviewer's job is different: code-against-spec, not code-against-plan.

## Workflow conventions

### Default: gitignore the folder

The `agent-run/` folder is pipeline scratch — regenerated per feature, stale fast. Add to your project's `.gitignore`:

```gitignore
# Agent pipeline artifacts (per-ticket scratch)
agent-run/
```

Artifacts stay local for the duration of the PR cycle and then get discarded with the branch.

### Move the valuable parts into the PR

Before opening the PR, copy the useful pieces into the PR description:

- **From `SPEC.md`** — paste `Goal` + `Acceptance criteria`. Now the reviewer knows what was asked.
- **From `QA_REPORT.md`** — paste the `Manual verification checklist` under a `Reviewer testing steps` heading. The reviewer runs it before approving.
- **From `REVIEW.md`** — if BLOCKING findings were fixed during the build, mention them in a `Decisions` section (example: "Initial draft had a race condition flagged by review; final uses a Redis lock."). ADVISORY-only findings are history; skip.
- **`IMPLEMENTATION_NOTES.md`** — skip. The code is the implementation.

### Alternative: commit `agent-run/` for an audit trail

If your team wants a per-feature audit trail (compliance, onboarding, postmortems), DON'T gitignore `agent-run/`. Commit it. Reviewers see the artifacts in the PR file tree but they're collapsed by default in most code-review UIs.

If you want a mixed policy (commit some runs, discard others), be explicit per branch — there's no clean middle ground at the gitignore level.

## Why manual orchestration

Single-process pipeline orchestration through a "ticket-runner" or "orchestrator" agent is unreliable in practice. The runtime decides on a case-by-case basis whether to spawn subagents (via the Task tool) or just inline the work in its own context. For small tasks it almost always inlines — and when it does, the reviewer's `readonly: true` and "fresh context" guarantees silently evaporate. The reviewer is now the same agent that wrote the implementation, with full memory of every choice. Its "fresh-eyes review" becomes a self-review by definition.

No amount of prompt wording reliably forces real subagent spawning from inside another agent's context. The runtime's spawn heuristics override prompt directives.

What DOES work reliably: **manual slash commands typed by the user**. When you type `/reviewer` as a separate prompt, the runtime treats it as a fresh subagent invocation. Each step gets a clean context. Adversarial separation holds.

So this repo splits the pipeline into four discrete subagents and asks you to fire them yourself, one at a time. Two extra keystrokes per ticket in exchange for actually getting the architecture you think you're getting.

### When you DO want fully automated orchestration

For runs where you need provable isolation without typing four commands (CI, overnight batch, audit-bait), use the **Makefile / CLI route** with per-role `agent -p` invocations. OS process isolation is bulletproof; the runtime can't inline what's in a separate process. Example:

```makefile
implement:
	agent -p "@implementer for ticket $(TICKET)" --mode agent --force

review: implement
	agent -p "@reviewer for ticket $(TICKET)" --mode ask

qa: review
	agent -p "@qa for ticket $(TICKET)" --mode agent --force
```

Each `agent -p` is a separate OS process with its own context window. Isolation is structural, not negotiated.

## On the write constraint for planner and reviewer

Both `planner` and `reviewer` are scoped to write a single file (`PLAN.md` and `REVIEW.md` respectively) and nothing else. The reviewer especially: it must not edit source, even when "just fix it" is tempting.

### Why the constraint is prompt-level, not tool-level

Earlier versions of these agents used Cursor's `readonly: true` flag to enforce the constraint at the system level. In practice that flag turned out to be too blunt — it blocked ALL writes including the markdown artifact the agent was supposed to produce. The planner couldn't write `PLAN.md`; the reviewer couldn't write `REVIEW.md`. The parent agent ended up writing them based on the subagent's output, which broke the whole "the planner produces the plan" model.

Current approach: `readonly: false` (Cursor / Codex) or `tools: Read, Write, Grep, Glob[, Bash]` (Claude Code), with a **strong prompt-level rule** that the agent may only write its one designated artifact. The frontmatter unlocks the runtime; the prompt enforces the discipline.

The trade-off: the constraint is now a professional rule the agent must follow, not a system-level guarantee. It's softer enforcement, but it actually works. If you see a planner editing source files or a reviewer "helpfully" fixing a bug, that's a violation worth catching in code review.

### Why this is OK for adversarial separation

The reviewer's cold-read guarantee comes from two things:

1. It runs in a fresh subagent context (Task-tool spawn), not the implementer's context.
2. It does not read `PLAN.md` or `IMPLEMENTATION_NOTES.md` — the spec and the diff are its only inputs.

Those two together mean the reviewer cannot be biased by the implementer's framing. The write constraint (only `REVIEW.md`, not source) is a separate guarantee — it prevents the reviewer from acting as a second implementer. The two guarantees are independent; one weakening doesn't compromise the other.

If you ever find yourself wanting to "just let the reviewer fix it," that's the signal to invoke `/implementer for ticket <id>` again with the review as input — not to bypass the separation.

## Customising per project

The agents are starting points. Real projects will want to:

- Adjust the testing-framework references in `qa.md` (Vitest is the default; swap for Jest, RSpec, pytest, etc.)
- Expand `reviewer.md` with domain-specific checks (payments, auth, multi-tenancy)
- Re-enable optional Jira / Confluence write-back in `spec-builder.md` once you trust the output (see git history for older `ticket-runner.md` for the template)
- Add a `domain-expert` subagent for non-trivial business logic if you have it

## License

MIT. See `LICENSE`.

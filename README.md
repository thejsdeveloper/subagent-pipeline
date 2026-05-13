# subagent-pipeline

A four-subagent dev pipeline you can drop into any project for spec-builder → implementer → reviewer → qa orchestration with structured handoffs. Designed for **manual orchestration** — you fire each subagent as a separate slash command — because that's the only way to guarantee fresh contexts and adversarial separation per step. Works with Cursor, Claude Code, and Codex via their native subagent paths.

## The four agents

| Agent | Role | Tool access |
|---|---|---|
| `spec-builder` | Fetches a Jira ticket via MCP, consolidates the spec from linked Confluence pages, writes `SPEC.md`. Stops. | Read + Write + read-only MCP |
| `implementer` | Reads `SPEC.md` + the convention chain, plans, codes, ships. Writes `IMPLEMENTATION_NOTES.md`. | Full read/write |
| `reviewer` | Reads the diff cold, outputs BLOCKING / ADVISORY / GOOD. Writes `REVIEW.md`. | **Read-only** (cannot mutate code) |
| `qa` | Writes table-driven tests + a manual verification checklist. Writes `QA_REPORT.md`. | Full read/write |

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
├── cursor/         # for .cursor/agents/
├── claude/         # for .claude/agents/
└── codex/          # for .codex/agents/
```

## Install

Pick the right folder for your editor and drop it into your project.

### Cursor

```bash
cd /path/to/your/project
mkdir -p .cursor/agents
cp /path/to/subagent-pipeline/cursor/*.md .cursor/agents/
```

Or symlink, so updates here flow into all your projects:

```bash
ln -s /path/to/subagent-pipeline/cursor /path/to/your/project/.cursor/agents
```

### Claude Code

```bash
cd /path/to/your/project
mkdir -p .claude/agents
cp /path/to/subagent-pipeline/claude/*.md .claude/agents/
```

### Codex

```bash
cd /path/to/your/project
mkdir -p .codex/agents
cp /path/to/subagent-pipeline/codex/*.md .codex/agents/
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

In your editor's main chat, run these **as four separate prompts**:

```
1. /spec-builder JIRA-1234
2. /implementer for ticket JIRA-1234
3. /reviewer for ticket JIRA-1234
4. /qa for ticket JIRA-1234
```

Each command must be a separate user input. Do not chain them in one message. Each fresh slash command is what guarantees a fresh subagent context.

### Without Jira

If you don't have a ticket, skip `spec-builder` and start with `implementer`. Use a kebab-case slug as the run ID (the implementer will create `agent-run/<slug>/` to hold artifacts):

```
1. /implementer Build the POST /refunds endpoint per openapi.yaml. Use slug add-refunds-endpoint.
2. /reviewer for the current diff (slug add-refunds-endpoint).
3. /qa for the current diff (slug add-refunds-endpoint).
```

## What it produces

The pipeline writes all artifacts to `agent-run/<ticket-id>/`:

```
agent-run/
└── PROJ-1234/
    ├── SPEC.md                  ← spec-builder
    ├── IMPLEMENTATION_NOTES.md  ← implementer
    ├── REVIEW.md                ← reviewer
    └── QA_REPORT.md             ← qa
```

For runs without a ticket, the slug is used instead (e.g., `agent-run/2026-05-13-add-tooltip/`).

Each artifact is the structured handoff to the next subagent. They also serve as a per-feature audit trail you can keep, archive, or discard at PR time. See [Workflow conventions](#workflow-conventions) for how to handle them.

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

## On readonly enforcement

The reviewer is the only agent with restricted tool access. The promise is: even if the user asks the reviewer to "just fix it quickly," the reviewer physically cannot edit files.

This matters because adversarial separation only works if the reviewer's incentives are different from the implementer's. Tool restriction enforces those different incentives at the system level.

If you ever find yourself wanting to "just let the reviewer fix it," that's the signal to invoke `/implementer for ticket <id>` again with the review as input — not to bypass the separation.

## Customising per project

The agents are starting points. Real projects will want to:

- Adjust the testing-framework references in `qa.md` (Vitest is the default; swap for Jest, RSpec, pytest, etc.)
- Expand `reviewer.md` with domain-specific checks (payments, auth, multi-tenancy)
- Re-enable optional Jira / Confluence write-back in `spec-builder.md` once you trust the output (see git history for older `ticket-runner.md` for the template)
- Add a `domain-expert` subagent for non-trivial business logic if you have it

## License

MIT. See `LICENSE`.

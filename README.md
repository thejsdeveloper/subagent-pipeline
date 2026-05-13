# subagent-pipeline

A four-agent dev pipeline you can drop into any project to get implementer → reviewer → qa orchestration with structured handoffs. Supports Cursor, Claude Code, and Codex via their respective subagent paths.

## The four agents

| Agent | Role | Tool access |
|---|---|---|
| `implementer` | Reads the convention chain (CONVENTIONS, ARCHITECTURE, openapi), plans, codes, ships | Full read/write |
| `reviewer` | Reads the diff cold, outputs BLOCKING / ADVISORY / GOOD | **Read-only** (cannot mutate code) |
| `qa` | Writes table-driven tests + a manual verification checklist | Full read/write |
| `ticket-runner` | Fetches a Jira ticket via MCP, consolidates spec from linked Confluence pages, runs the pipeline, surfaces a final summary | Full read/write + read-only MCP |

The reviewer's read-only constraint is the heart of the pattern. Adversarial separation isn't a prompt instruction; it's a tool-level guarantee.

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
cp /path/to/agents/cursor/*.md .cursor/agents/
```

Or symlink, so updates here flow into all your projects:

```bash
ln -s /path/to/agents/cursor /path/to/your/project/.cursor/agents
```

### Claude Code

```bash
cd /path/to/your/project
mkdir -p .claude/agents
cp /path/to/agents/claude/*.md .claude/agents/
```

### Codex

```bash
cd /path/to/your/project
mkdir -p .codex/agents
cp /path/to/agents/codex/*.md .codex/agents/
```

## The convention chain

Every project that uses these agents should have three files at the repo root:

- **CONVENTIONS.md** — naming, error patterns, testing style, idioms
- **ARCHITECTURE.md** — folder layout, layer rules, hard dependency rules
- **openapi.yaml** (or `schema.prisma`, or SQL DDL) — the canonical contract

The implementer reads all three before writing any code. The reviewer checks against them. The qa agent runs the project's testing convention.

If you don't have these files yet, write tiny versions — even 30 lines beats nothing. Iterate as the agents reveal what's ambiguous.

## Usage

In your editor's main chat:

```
/implementer Build the POST /refunds endpoint per openapi.yaml.
/reviewer Review the diff.
/qa Generate tests and a manual checklist.
```

Or for the full Jira-integrated flow:

```
/ticket-runner JIRA-1234
```

The ticket-runner fetches the ticket via the Atlassian MCP, pulls linked Confluence pages, writes `SPEC.md`, runs implementer → reviewer → qa, and surfaces a final summary. PR creation and ticket status updates are intentionally manual at this stage — the agent does not write to Jira or Confluence. (Re-enable write-back later by re-adding the relevant steps to `ticket-runner.md`.)

## What it produces

The pipeline writes four artifacts to the repo root:

| File | Written by | Contents |
|---|---|---|
| `SPEC.md` | ticket-runner | Consolidated requirement from Jira + Confluence |
| `IMPLEMENTATION_NOTES.md` | implementer | What was built, assumptions, edge cases |
| `REVIEW.md` | reviewer | BLOCKING / ADVISORY / GOOD findings |
| `QA_REPORT.md` | qa | Tests added, coverage gaps, manual checklist |

Each artifact is the structured handoff to the next agent. See **Workflow conventions** below for how to handle them at PR time.

## Workflow conventions

The four artifacts (`SPEC.md`, `IMPLEMENTATION_NOTES.md`, `REVIEW.md`, `QA_REPORT.md`) are pipeline scratch, not project source. Default policy: **gitignore them.** The valuable parts move to the PR description.

### Gitignore them

Add to your project's `.gitignore`:

```gitignore
# Agent pipeline artifacts (regenerated per feature)
SPEC.md
IMPLEMENTATION_NOTES.md
REVIEW.md
QA_REPORT.md
```

Why: PRs should show the diff, not 200 lines of markdown about the diff. Committing the artifacts adds noise without signal, and they go stale fast when the implementer iterates.

### What to do instead

Before opening the PR, copy the useful pieces into the PR description:

- **From `SPEC.md`** — paste the `Goal` and `Acceptance criteria` into the PR description. The reviewer now knows what was asked.
- **From `QA_REPORT.md`** — paste the `Manual verification checklist` under a `Reviewer testing steps` heading. The reviewer runs the steps before approving.
- **From `REVIEW.md`** — if any BLOCKING findings were fixed during the build, mention them in a `Decisions` section (example: "Initial draft had a race condition flagged by review; final version uses a Redis lock."). ADVISORY-only findings are history; skip.
- **`IMPLEMENTATION_NOTES.md`** — skip. The code is the implementation.

### Alternative: commit to `.agent-runs/`

If your team wants a per-feature audit trail (compliance, onboarding, postmortems), commit to a dedicated subfolder instead of the repo root.

In `.gitignore`:

```gitignore
# Discard the artifacts at repo root
/SPEC.md
/IMPLEMENTATION_NOTES.md
/REVIEW.md
/QA_REPORT.md
```

Then in `ticket-runner.md` steps 3 and 5, change the artifact path from `SPEC.md` to `.agent-runs/<ticket-id>/SPEC.md` (same for the other three). Reviewers see them only if they click into the folder, which keeps the PR diff clean while preserving the history.

## Verifying real subagent isolation

The `readonly: true` flag on the reviewer only matters when the reviewer **actually runs as a separate subagent**. If the parent agent role-plays the reviewer inline instead of spawning a fresh subagent via the Task tool, the readonly constraint becomes irrelevant — the parent has full tool access and can write anything.

This is a real failure mode. The agent runtime has efficiency heuristics that sometimes inline what should be spawned. The ticket-runner workflow includes explicit Task-tool directives to fight this, but you still need to verify on every run.

### Three checks per run

1. **REVIEW.md content quality.** Real adversarial reviews trend toward specific gripes ("the reduce on line 42 throws TypeError if the input is empty"). Self-reviews trend toward flattery ("well-structured, follows conventions"). If REVIEW.md reads like marketing, the reviewer was the parent role-playing.

2. **Conversation tree in your IDE.** Genuine subagent spawns show as nested blocks (Cursor: "Subagent: reviewer" chip; Claude Code: indented sub-conversation). A flat conversation with no nesting means no spawn happened.

3. **Timestamp gaps.** Real spawns add a noticeable "starting subagent..." pause (typically 10-30 seconds for a fresh context). Inline role-play is continuous with no gap.

### What to do when it happens

If you spot inline role-play on a run, re-invoke the reviewer explicitly:

```
@reviewer Spawn yourself as a fresh subagent via the Task tool. Read the
diff at HEAD cold. You did not write this code. Output BLOCKING / ADVISORY /
GOOD to REVIEW.md.
```

The "Spawn yourself via the Task tool" phrase is the lever. It forces the runtime to actually delegate.

### Caveat

The runtime ultimately decides. Even with explicit directives, an agent may decide spawning is overkill for tiny tasks. The directives raise the probability of real delegation; they don't guarantee it. **Every run, check for the subagent boundaries before trusting the REVIEW.md.**

## Customising per project

The agents are starting points. Real projects will want to:

- Adjust the testing-framework references in `qa.md` (Vitest is the default; swap for Jest, RSpec, pytest, etc.)
- Expand `reviewer.md` with domain-specific checks (payments, auth, multi-tenancy)
- Re-enable Jira / Confluence write-back in `ticket-runner.md` once you trust the output (currently disabled — see step 6 in the previous git revision for the template)
- Add a `domain-expert` subagent for non-trivial business logic if you have it

## On readonly enforcement

The reviewer is the only agent with restricted tool access. The promise is: even if the parent agent or the user asks the reviewer to "just fix it quickly," the reviewer physically cannot edit files.

This matters because adversarial separation only works if the reviewer's incentives are different from the implementer's. Tool restriction enforces those different incentives at the system level.

If you ever find yourself wanting to "just let the reviewer fix it," that's the signal to invoke `/implementer` again with the review as input — not to bypass the separation.

## License

MIT. See `LICENSE`.

# agents

A four-agent dev pipeline you can drop into any project to get implementer → reviewer → qa orchestration with structured handoffs. Supports Cursor, Claude Code, and Codex via their respective subagent paths.

## The four agents

| Agent | Role | Tool access |
|---|---|---|
| `implementer` | Reads the convention chain (CONVENTIONS, ARCHITECTURE, openapi), plans, codes, ships | Full read/write |
| `reviewer` | Reads the diff cold, outputs BLOCKING / ADVISORY / GOOD | **Read-only** (cannot mutate code) |
| `qa` | Writes table-driven tests + a manual verification checklist | Full read/write |
| `ticket-runner` | Fetches a Jira ticket via MCP, consolidates spec from linked Confluence pages, runs the pipeline, reports back to Jira | Full read/write + MCP |

The reviewer's read-only constraint is the heart of the pattern. Adversarial separation isn't a prompt instruction; it's a tool-level guarantee.

## Why per-provider folders

The same agents work across Cursor, Claude Code, and Codex, but the frontmatter syntax for tool restriction differs:

- **Cursor:** `readonly: true` to block writes
- **Claude Code:** `tools:` allowlist (e.g., `tools: Read, Grep, Glob, Bash`)
- **Codex:** mirrors Cursor for now (the spec is in flux)

Each provider folder ships agents in the right frontmatter format. The agent bodies are identical across providers.

## Repo layout

```
agents/
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

The ticket-runner fetches the ticket via the Atlassian MCP, pulls linked Confluence pages, writes `SPEC.md`, runs implementer → reviewer → qa, and posts back to Jira with the PR link and the AC checklist.

## What it produces

The pipeline writes four artifacts to the repo root:

| File | Written by | Contents |
|---|---|---|
| `SPEC.md` | ticket-runner | Consolidated requirement from Jira + Confluence |
| `IMPLEMENTATION_NOTES.md` | implementer | What was built, assumptions, edge cases |
| `REVIEW.md` | reviewer | BLOCKING / ADVISORY / GOOD findings |
| `QA_REPORT.md` | qa | Tests added, coverage gaps, manual checklist |

Each artifact is the structured handoff to the next agent. The artifacts also serve as the audit trail for the PR.

## Customising per project

The agents are starting points. Real projects will want to:

- Adjust the testing-framework references in `qa.md` (Vitest is the default; swap for Jest, RSpec, pytest, etc.)
- Expand `reviewer.md` with domain-specific checks (payments, auth, multi-tenancy)
- Add project-specific status names to `ticket-runner.md` step 6 ("In Review" vs "Code Review" vs "Ready for Review")
- Add a `domain-expert` subagent for non-trivial business logic if you have it

## On readonly enforcement

The reviewer is the only agent with restricted tool access. The promise is: even if the parent agent or the user asks the reviewer to "just fix it quickly," the reviewer physically cannot edit files.

This matters because adversarial separation only works if the reviewer's incentives are different from the implementer's. Tool restriction enforces those different incentives at the system level.

If you ever find yourself wanting to "just let the reviewer fix it," that's the signal to invoke `/implementer` again with the review as input — not to bypass the separation.

## License

MIT. See `LICENSE`.

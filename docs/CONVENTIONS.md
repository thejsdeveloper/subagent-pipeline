# CONVENTIONS

> **Template.** Replace this content with your project's actual conventions during `/onboarding`. The agents read this file when planning, implementing, reviewing, and QA-ing. Keep it short — better short and true than long and aspirational.

## Language and runtime
- Language: <e.g., TypeScript 5.4>
- Runtime: <e.g., Node 20>

## Linter / formatter
- Linter: <e.g., ESLint with @typescript-eslint>
- Formatter: <e.g., Prettier>
- Command to run before commit: <e.g., `pnpm lint && pnpm format:check`>

## Tests
- Framework: <e.g., Vitest>
- File naming: <e.g., `*.test.ts` collocated next to source; e2e in `e2e/`>
- Mocking discipline: <e.g., "Mock at the adapter layer (`lib/clients/*`), never inside business logic.">
- Command to run: <e.g., `pnpm test`>

## Branching and commits
- Branching model: <trunk-based | GitFlow | main + feature branches>
- Commit message style: <Conventional Commits | freeform | other>
- PR requirements: <CI green, 1 approver, no merge commits, etc.>

## Things that block a PR
- Any failing test or lint check
- A new endpoint not declared in `openapi.yaml` (backend / full-stack only)
- A change that breaks an Accepted ADR in `docs/adr/`

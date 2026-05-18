---
name: brownfield-onboarding
description: How to bootstrap the convention chain in an existing repo that has no docs. Used by /onboarding when AGENTS.md, docs/CONVENTIONS.md, and docs/ARCHITECTURE.md are missing.
---

# brownfield-onboarding

Most repos that adopt this pipeline are not greenfield. They already have code, conventions (often unwritten), and architecture (often undocumented). This skill is the discovery sequence that turns "no docs" into "minimum viable docs" in one pass.

## Discovery sequence

### 1. Read the manifest files first

- `package.json` (Node), `pyproject.toml` / `requirements.txt` (Python), `go.mod` (Go), `Cargo.toml` (Rust), `pom.xml` / `build.gradle` (JVM)
- `tsconfig.json`, `next.config.js`, `vite.config.ts`, `webpack.config.js`
- `Dockerfile`, `docker-compose.yml`
- `.github/workflows/*`, `.gitlab-ci.yml`, `Jenkinsfile`

This tells you: language, framework, runtime, test framework, build tool, CI provider.

### 2. Read top-level folder names

- `src/`, `app/`, `pages/` — likely the application code root
- `lib/`, `utils/`, `helpers/` — shared utilities
- `db/`, `prisma/`, `migrations/` — data layer
- `api/`, `routes/`, `controllers/` — server-side route handlers (backend / full-stack)
- `components/`, `views/`, `templates/` — frontend
- `apps/`, `packages/`, `services/` — monorepo
- `tests/`, `__tests__/`, `e2e/` — test layout

### 3. Read 2-5 representative files to confirm style

Don't read everything. Pick a router file, a model/component file, a test file, and a config file. That's enough to infer:
- Import style (relative vs absolute)
- Whether the project uses TypeScript strictly or loosely
- Whether tests are collocated or in a separate tree
- Mocking discipline (real DB vs mocks)

### 4. Detect classifications

- **frontend** — has bundler config, has UI framework, no server route handlers
- **backend** — has route handlers, has ORM or DB driver, no UI build
- **full-stack** — has both (Next.js with API routes, Remix loaders, T3 stack, etc.)
- **monorepo** — has workspaces (`apps/`, `packages/`, or `pnpm-workspace.yaml`, etc.)

Surface the classification to the user in one line and wait for confirmation.

## Calibration questions (fixed set — do not invent more)

Ask these one at a time. Skip any answered by the repo itself.

1. **Testing framework.** If `package.json` shows Vitest or Jest, confirm. Otherwise ask.
2. **Branching model.** Trunk-based, GitFlow, or "main + feature branches"?
3. **Deploy target.** Vercel / AWS / on-prem / Kubernetes / unknown / not deployed yet?
4. **OpenAPI spec.** Backend / full-stack only: does one exist? Want one?
5. **Linter / formatter.** Read the repo to confirm; ask only if unclear.

No more than five questions. The goal is fast onboarding, not interrogation.

## Output

Generate these four files. Keep each one short.

1. **`AGENTS.md`** (root) — project overview, stack, convention chain pointer, how to invoke the pipeline
2. **`docs/CONVENTIONS.md`** — language version, linter, test framework, branching, anything that would block a PR
3. **`docs/ARCHITECTURE.md`** — top-level folder map with one-line purpose, layering rules, external dependencies
4. **`docs/adr/0001-record-architecture-decisions.md`** — meta-ADR, follow the `architectural-decision-records` skill

## Rules

- Do not invent architecture rules that aren't actually enforced. Aspirational rules become liabilities.
- Do not write production code during onboarding. Docs only.
- Keep every doc short. The user will refine — that's the point.
- If the codebase has any existing diagrams worth keeping, copy them into `docs/diagrams/` and link from `ARCHITECTURE.md`. Don't generate new ones in onboarding — `/architect` handles that later.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "The codebase is small; AGENTS.md doesn't need to mention the stack" | Every codebase grows. The planner reads AGENTS.md next; missing stack info means the planner re-derives it from scratch every time. |
| "I'll fill in CONVENTIONS.md later when we have conventions" | Onboarding is the moment you have full attention. Empty CONVENTIONS = drift starts immediately. |
| "I'll just ask the user everything" | Discovery via reading beats interrogation. Read the manifest files first; ask only what the code can't answer. |
| "Aspirational architecture rules describe where we're going" | The reviewer enforces what's written today. Aspirational rules turn into false positives. |
| "Adding a calibration question feels useful" | The fixed five exist on purpose. More questions = onboarding fatigue. |

## Red Flags

- Writing `CONVENTIONS.md` without reading `package.json` / `pyproject.toml` / `go.mod` first
- Asking the user which test framework they use when it's visible in the manifest
- `ARCHITECTURE.md` contains layering rules no existing code follows
- Generated files contain placeholder TODOs instead of real, project-specific content
- onboarding ran `git add` / `git commit` / `git push`

## Verification

- [ ] `AGENTS.md`, `docs/CONVENTIONS.md`, `docs/ARCHITECTURE.md`, `docs/adr/0001-record-architecture-decisions.md` all exist
- [ ] `AGENTS.md` Stack section names language, framework, tests, and deploy target — no TODOs
- [ ] `CONVENTIONS.md` cites the actual lint and test commands, not placeholders
- [ ] `ARCHITECTURE.md` folder map matches the real top-level folders of the repo
- [ ] Every layering rule in `ARCHITECTURE.md` is grounded in observed code
- [ ] No git state-changing commands were run

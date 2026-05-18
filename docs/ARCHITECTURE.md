# ARCHITECTURE

> **Template.** Replace this content with your project's actual architecture during `/onboarding`. Keep layering rules concrete — they're enforced by the reviewer agent.

## Top-level folder map
- `src/` — <one-line purpose>
- `lib/` — <one-line purpose>
- `db/` — <one-line purpose>
- `tests/` — <one-line purpose>

(Replace with your actual top-level folders.)

## Layering rules
- <Layer A> may import from <Layer B>, but never the reverse.
- <Layer X> is the only layer that talks to <external system>.
- Business logic does NOT import from <UI / DB / transport>.

Each rule should be a one-liner that the reviewer can check against a diff. If a rule needs three sentences to explain, it's not a rule yet — it's a guideline.

## External dependencies
- Database: <e.g., Postgres via Prisma>
- Queue / event bus: <e.g., SQS, RabbitMQ, none>
- Third-party APIs: <e.g., Stripe, Sendgrid>
- Auth provider: <e.g., Auth0, Clerk, in-house>

## Diagrams
Diagrams live in `docs/diagrams/` as Mermaid in Markdown. Default to C4 Level 2 (containers). See the `architecture-diagrams` skill for conventions. Generate or update via `/architect`.

## Accepted decisions
See `docs/adr/` for the full record. The meta-ADR is `0001-record-architecture-decisions.md`.

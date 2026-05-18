# Credits

This project stands on the work of others. Specific debts:

## Skills

The skill format and several of the skill bodies in `skills/` were adopted from open work by:

- **[Matt Pocock](https://github.com/mattpocock)** — original author of [grill-me](https://github.com/mattpocock/skills/blob/main/skills/productivity/grill-me/SKILL.md) and the broader [skills repository](https://github.com/mattpocock/skills). The interview-the-user-relentlessly approach is his.

- **[intent-driven-dev](https://github.com/intent-driven-dev) / [intent-driven-template](https://github.com/intent-driven-dev/intent-driven-template)** — `gherkin-authoring`, `architectural-decision-records`, and `architecture-diagrams` (their `c4-diagrams`) follow the structure and much of the wording from `.agents/skills/` in their template repo. Where we diverge, it is to remove choice points (we lock in MADR-minimal for ADRs and plain Mermaid for diagrams) rather than to improve on the underlying ideas.

- **[Jesse Vincent / obra](https://github.com/obra) / [superpowers](https://github.com/obra/superpowers)** (MIT, on the `experiment/superpowers` branch only) — `brainstorming`, `writing-plans`, `executing-plans`, and `verification-before-completion` are copied verbatim and wired into spec-builder, planner, implementer, and qa respectively. This is a comparison branch to evaluate whether the added discipline (HARD-GATE on design approval, evidence-before-claims verification) improves outcomes over the lean baseline on `main`.

## Templates

- **MADR (Markdown Architectural Decision Records)** — `skills/architectural-decision-records/templates/madr-minimal.md` is derived from [adr/madr v4.0.0](https://github.com/adr/madr/blob/4.0.0/template/adr-template-minimal.md).

## Concepts

- **C4 Model** — Simon Brown's [C4 model](https://c4model.com/) for software architecture. Used as the level vocabulary (System Context, Container, Component) in the architecture-diagrams skill.

- **Gherkin / Cucumber** — the BDD scenario syntax used in the gherkin-authoring skill.

If we've missed an attribution that should be here, open an issue or PR and we'll add it.

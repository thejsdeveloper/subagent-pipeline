---
name: gherkin-authoring
description: Use when drafting, reviewing, or improving Gherkin scenarios in SPEC.md — GIVEN/WHEN/THEN acceptance criteria, Scenario Outlines, Backgrounds, Rules, Doc Strings, Data Tables, tags, or Gherkin embedded in Markdown.
---

# Gherkin Authoring

## Overview

Write Gherkin as executable examples of business behavior. Use domain language, concrete examples, and observable outcomes. Keep implementation and UI mechanics out — those belong in step definitions, not the scenario.

## Scope

Use this for standalone `.feature` files and Gherkin embedded in Markdown (the usual case in SPEC.md). When Gherkin is inside Markdown, edit only the Gherkin block — preserve fences, headings, and surrounding prose. Return the Markdown wrapper with only the Gherkin section changed.

## Workflow

1. Identify the Gherkin region: full `.feature` file, fenced ```gherkin block, indented block, or inline scenario text in Markdown.
2. Preserve the wrapper unless explicitly asked to change it.
3. For each behavior, clarify three things: initial state, the event, the observable outcome.
4. Choose the smallest structure that expresses the behavior: `Feature`, optional `Rule`, `Background`, `Scenario` (or `Scenario Outline` + `Examples` for data variants).
5. Keep scenarios concrete and short — usually 3–5 steps.
6. Review syntax before returning: colons in the right places, step keywords used correctly, observable outcomes, table/doc-string formatting.

## Quick Reference

| Construct | Use for | Syntax note |
| --- | --- | --- |
| `Feature:` | One high-level capability per feature document or block | Requires `:` |
| `Rule:` | Group scenarios under one business rule | Requires `:` |
| `Scenario:` / `Example:` | One concrete example | Requires `:` |
| `Background:` | Short shared context for following scenarios | Requires `:`; one per `Feature` or `Rule` |
| `Scenario Outline:` | Same behavior with varied data | Requires `Examples:` and `<parameter>` placeholders |
| `Examples:` | Data rows for an outline | Requires `:` and a table |
| `Given` | Known state or precondition | No `:` |
| `When` | Event or action | No `:` |
| `Then` | Observable outcome | No `:` |
| `And` / `But` | Continue the previous step type | No `:` |
| `*` | Bullet-like step list | Use sparingly for list-style setup |
| `@tag` | Group or filter features/scenarios | Place on the line above the item tagged |
| `#` | Line comment | Line comments only; no block comments |
| `"""` | Doc String | Passed as final step argument |
| `\|` | Data Table | Passed as final step argument |

## Authoring rules

- Use the language domain experts use. Don't translate business behavior into UI clicks, HTTP calls, database rows, queues, mocks, or implementation details.
- `Given` puts the system in a known state. Avoid user interaction in `Given`.
- `When` describes one meaningful event. One per scenario, ideally.
- `Then` describes an outcome visible to a user or external system. Don't assert hidden database state unless that hidden state is the actual external contract.
- Use `And` / `But` to improve flow, not to hide new phases of the scenario.
- Don't reuse identical step text under different step keywords. Cucumber ignores `Given`/`When`/`Then` when matching step definitions, so identical text becomes one step.
- Use two-space indentation unless the existing file uses a different style.
- Keep `Background` short. If it grows past four lines, raise the abstraction or split by `Rule` / `Feature`.
- Use `Scenario Outline` only when examples share the same behavior and differ by data.

## Escape sequences in Data Tables

- `\|` for a pipe inside a cell
- `\n` for a newline
- `\\` for a backslash

## Example

Markdown wrapper preserved; only the Gherkin block authored:

````markdown
## Acceptance Criteria

```gherkin
Feature: Password reset
  Rule: Reset links expire after their allowed lifetime

    Scenario: Customer resets their password before the link expires
      Given Priya has requested a password reset
      And the reset link is still valid
      When Priya chooses a new password with the reset link
      Then she can sign in with the new password

    Scenario: Customer uses an expired reset link
      Given Priya has requested a password reset
      And the reset link has expired
      When Priya tries to choose a new password with the reset link
      Then she is told the reset link has expired
      And her password is unchanged
```
````

## Scenario Outline example

```gherkin
Scenario Outline: Checkout totals
  Given a cart with <items> items at $<price> each
  When the customer checks out
  Then the total is $<total>

  Examples:
    | items | price | total |
    | 1     | 10    | 10    |
    | 3     | 10    | 30    |
    | 0     | 10    | 0     |
```

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Returning only a fenced Gherkin block when the input was Markdown | Return the original Markdown wrapper with only the Gherkin content changed. |
| `Feature Checkout` or `Scenario: Place order:` | Add the missing colon after `Feature`; remove the extra colon from the scenario title. |
| `Given I click the checkout button` | Move the interaction to `When`; describe state in `Given`. |
| `Then an order row exists in the database` | Prefer an observable result (order confirmation, status, email). |
| Reusing identical step text for `Given` and `Then` | Reword so the domain meaning is distinct. |
| Long scripts with many UI actions | Raise the abstraction; keep the scenario focused on the behavior. |
| Large `Background` sections | Split by `Rule` or `Feature`, or move setup into higher-level steps. |
| `Scenario Outline` with one example row | Just use `Scenario`; outlines are for data variation. |

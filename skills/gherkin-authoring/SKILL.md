---
name: gherkin-authoring
description: How to write GIVEN/WHEN/THEN acceptance scenarios in SPEC.md so the QA agent can lift them straight into table-driven tests. Use when authoring or revising the Scenarios section of a SPEC.
---

# gherkin-authoring

Acceptance scenarios in SPEC.md should be Gherkin-style: GIVEN preconditions, WHEN an action, THEN an expected outcome. This gives the QA agent a direct map from spec to tests.

## Format

```
Scenario: <short name in plain English>
  GIVEN <starting state>
    AND <additional precondition>
  WHEN <user or system action>
  THEN <observable outcome>
    AND <additional outcome>
```

## Rules

- One scenario per user-facing outcome. Don't bundle.
- Cover the happy path FIRST, then 1-3 edge cases. Skip exhaustive enumeration — the QA agent will fill in branches from the diff.
- Write outcomes that can be observed. "User feels confident" is not testable. "The page shows a green confirmation toast for 3 seconds" is testable.
- Use the same nouns the SPEC's Goal section uses. Consistency between Goal, AC, and Scenarios is the point.
- Do NOT include implementation detail. "WHEN the user clicks Submit" is good. "WHEN the onClick handler dispatches saveOrder()" is bad.

## Example

```
Scenario: Empty cart cannot check out
  GIVEN the user has 0 items in their cart
  WHEN they navigate to /checkout
  THEN they are redirected to /cart
    AND a toast reads "Add at least one item before checking out"

Scenario: Single-item checkout succeeds
  GIVEN the user has 1 item in their cart
    AND their saved payment method is valid
  WHEN they click "Place order"
  THEN they see the order confirmation page
    AND the order id is visible
    AND the cart is emptied
```

## Anti-patterns

- Writing scenarios after the code is done — they become checklists, not specs.
- Coupling scenarios to specific selectors, IDs, or DOM structure.
- One mega-scenario that covers the entire flow. Split it.

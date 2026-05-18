---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time.

If a question can be answered by exploring the codebase, explore the codebase instead.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "The user is busy, I should batch all my questions" | Batched questions get cursory answers. One-at-a-time gets thoughtful ones. |
| "Faster to ask than to read the code" | Asking what code can answer wastes the user's attention. Read first. |
| "I'll skip the recommended answer to stay neutral" | A recommendation lets the user accept with a single word. No recommendation = the user does your job for you. |

## Red Flags

- 3+ questions in one message
- Philosophical questions ("what is the goal here?") when concrete ones would do
- Questions asked without a proposed default answer
- Asking before reading the relevant code

## Verification

- [ ] Every question was asked one at a time
- [ ] Every question included a recommended answer
- [ ] No question had an answer findable in the codebase
- [ ] Shared understanding was confirmed before any artifact was written

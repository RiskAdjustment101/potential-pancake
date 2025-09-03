# /review

Perform a comprehensive code review of recent changes.

## Steps

1. Read the diff or changed files.
2. Produce a **risk-ranked checklist** with two sections:
   - Must Fix (logic bugs, security issues, a11y, performance, broken tests)
   - Nice to Have (style, naming, small refactors, comments)
3. Link directly to affected lines or files.
4. Ask: "Do you want me to fix the Must Fix items now?"
5. If yes, propose changes one file at a time; show diffs before applying.
6. Summarize review results and fixes.

## Scope

- Prioritize clarity, correctness, and accessibility.
- Ensure UI follows **shadcn/ui dark theme tokens** from `CLAUDE.md`.
- Ensure new code has at least one unit or component test.

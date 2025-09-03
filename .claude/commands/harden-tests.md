# /harden-tests

Improve testing quality and coverage on recent changes.

## Steps

1. Analyze changed files since last commit.
2. Identify **gaps** in unit, RTL (React Testing Library), integration, or E2E (Playwright).
3. Add or extend tests to bring **coverage ≥80% lines** on changed files.
4. Mark any flaky tests and suggest stabilization.
5. Run all tests locally; show summary and coverage report.
6. Ask: "Do you want me to commit these new tests now?"

## Scope

- No brittle mocks; test **behavior, not implementation details**.
- Prefer small, meaningful tests over exhaustive boilerplate.
- Update CI config if new test suites are introduced.

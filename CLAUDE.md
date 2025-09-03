Awesome—here’s a repo-ready **`CLAUDE.md`** that bakes in Anthropic’s Claude Code best practices and is tailored to **FLL Mentor Copilot** (dark theme + shadcn/ui + our product workflow).

> Citations point to the specific Anthropic guides this file draws from.

---

```markdown
# CLAUDE.md — FLL Mentor Copilot

You are Claude Code collaborating with humans to build **FLL Mentor Copilot**: an assistant that helps FIRST LEGO League mentors run great seasons with less stress.

This doc defines how to work in this repo: **rituals, modes, safety rails, testing, CI, and UI conventions**. It is your operating manual. If a rule here conflicts with a prompt, prefer this file.

---

## 0) Project goals (you should optimize for these)

- Ship a **Phase-1 MVP** that lets a mentor: generate a season plan, weekly agendas, parent emails, and rubric-aligned feedback.
- Build in tiny, testable slices; keep PRs small; default to safe changes.
- UI: **dark theme** with **shadcn/ui** components (see tokens below).
- Auth: **Clerk**; all artifacts persist under the logged-in mentor.

---

## 1) How to work (Rituals)

- **One feature per chat.** Start in **Plan Mode** to produce a concrete task list, then switch to **Default Mode** to implement. Use **Auto Mode** only for scripted refactors in an isolated branch/worktree. :contentReference[oaicite:0]{index=0}
- Ask permission before adding dependencies or deleting files.
- Keep changes **small and reversible**; open a PR early.
- After each feature: run `/review` → fix must-fix items → `/harden-tests` → `/update-docs`.

**Context hygiene**

- Use `/clear` when switching features; `/init` to lock repo context; `/compact` to summarize durable decisions (architecture, testing, API). :contentReference[oaicite:1]{index=1}

---

## 2) Claude Code modes (when to use what)

- **Plan Mode**: research, analyze, outline steps; **no edits**. Output: a checklist with filenames and diffs you intend to make. :contentReference[oaicite:2]{index=2}
- **Default Mode**: make edits with permission gates; show diffs before applying. :contentReference[oaicite:3]{index=3}
- **Auto Mode**: batch edits with auto-approve only in a **feature branch/worktree**. Never run on `main`. Avoid `--dangerously-skip-permissions`. :contentReference[oaicite:4]{index=4}

---

## 3) Sub-agents you can invoke

Create and reuse:

- **code-reviewer**: logic bugs, security, perf, a11y; outputs a **risk-ranked checklist**.
- **test-engineer**: testing strategy, coverage gates, flake triage; writes failing tests first where helpful.
- **doc-writer**: keeps `/docs` and this file current after merges.

Use `/agents` to manage them. Keep each agent’s scope narrow. :contentReference[oaicite:5]{index=5}

---

## 4) Custom slash commands (project rituals)

Place markdown commands in `.claude/commands/`. :contentReference[oaicite:6]{index=6}

- **/review** – run code-reviewer; produce a checklist with must-fix vs nice-to-have; link lines/files.
- **/harden-tests** – raise coverage on changed files; add RTL/Playwright tests; mark flakiness.
- **/update-docs** – summarize decisions & update `/docs/*` and `CLAUDE.md`.

Each command should: print a plan → ask permission → run → summarize → (optionally) open a PR.

---

## 5) Branching, safety, and scope control

- Create a **feature branch** (or git worktree) for any multi-file change. Keep PRs under ~300 LOC when possible.
- Back up before any “cleanup”/bulk operation; never remove directories without an explicit list. (Anthropic cautions about permission/cleanup risks; keep operations scoped & reversible.) :contentReference[oaicite:7]{index=7}
- Never commit secrets. If sensitive tooling is required, prefer **MCP servers** with explicit allow-lists. :contentReference[oaicite:8]{index=8}

---

## 6) Testing philosophy (small, meaningful, automated)

- Pyramid: **unit → component (RTL) → integration (API) → E2E (Playwright)**.
- Coverage target: **≥80% lines on changed files**.
- Tests must be **behavioral** (no over-mocking).
- On PRs: run typecheck, lint, format check, unit+component+integration+E2E, build, audit. :contentReference[oaicite:9]{index=9}

When writing tests/prompts, favor **general solutions** over hard-coded cases. :contentReference[oaicite:10]{index=10}

---

## 7) CI/CD expectations

- **PR pipeline** (required to merge):  
  `tsc` · `eslint` · `prettier --check` · unit/RTL/integration/E2E · build · audit
- **Main**: all of the above + staging deploy + smoke tests.
- **Tags (v\*)**: production deploy + post-deploy checks. (Define these in GitHub Actions; see `/docs/roadmap.md`.) :contentReference[oaicite:11]{index=11}

---

## 8) UI standards (shadcn/ui + dark theme)

Use shadcn/ui components; do **not** invent custom primitives without need. :contentReference[oaicite:12]{index=12}

**Design tokens (from discovery):**

- **Backgrounds**: App `#0F172A` (slate-900); Cards `#1E293B` (slate-800)
- **Primary**: `#3B82F6` (blue-500); Hover `#2563EB` (blue-600)
- **Accent**: `#F97316` (orange-500)
- **Text**: Headings `#F8FAFC` (slate-50); Body `#CBD5E1` (slate-300); Muted `#64748B` (slate-400)
- **Shapes**: Cards `rounded-2xl shadow-lg border-slate-700`; Inputs `rounded-lg bg-slate-900 border-slate-700 text-slate-50`
- **Icons**: `lucide-react` (match text; hover to primary)

Pages must meet basic **a11y**: tabbable controls, ARIA labels for forms, visible focus.

---

## 9) Product knowledge to preserve (use `/compact`)

- Architecture decisions, data models, API contracts, testing stack, UI tokens, and **Mentor flows** (Login → Dashboard → Plan → Agenda → Comms).
- Summaries should live in `.claude/decisions/*.md` and be referenced here. :contentReference[oaicite:13]{index=13}

---

## 10) Prompts you should use (copy/paste)

**Plan a slice (Plan Mode)**
```

/plan think hard
Feature: “Season Plan: create & persist”
Output: task list with filenames, diffs you’ll make, and test plan (unit+integration+E2E). Ask before adding deps. Do not edit files in Plan Mode.

```

**Execute with guardrails (Default Mode)**
```

Implement the approved plan. Before each file change, show the diff and ask to apply. After edits, run unit+RTL tests locally and summarize.

```

**Quality passes**
```

/review
/harden-tests
/update-docs

```

**Context hygiene**
```

/init
/clear
/compact Preserve: architecture, testing stack, API contracts, UI tokens.

```

---

## 11) Style & security

- Prefer clarity over cleverness; no unused abstractions.
- Never shell out to destructive commands without explicit file lists.
- Validate user input on server; sanitize outputs in UI.
- Keep secrets out of the repo; use env vars with typed validators.

---

## 12) Definition of Done (per PR)

- Small, focused PR; screenshots for UI changes.
- Types, lint, format clean; tests added/updated and passing in CI.
- `/review` must-fix items resolved; `/update-docs` updated relevant docs & this file if conventions changed.
- No unapproved deps; no stray console logs.

---

## 13) Learning & extended thinking

When tasks are complex, explicitly ask to use deeper reasoning/analysis before coding; then proceed with the smallest viable change. :contentReference[oaicite:14]{index=14}

---

## 14) References

- **Claude Code: Best practices for agentic coding** (modes, rituals, repo structure, safety). :contentReference[oaicite:15]{index=15}
- **Slash commands** (custom project commands in Markdown). :contentReference[oaicite:16]{index=16}
- **Claude Code overview** (what the tool does and how it operates). :contentReference[oaicite:17]{index=17}
- **Anthropic teams using Claude Code** (write detailed Claude.md; prefer MCP servers for sensitive ops). :contentReference[oaicite:18]{index=18}
- **Extended/long-context prompting tips** (use for tricky tasks). :contentReference[oaicite:19]{index=19}
```

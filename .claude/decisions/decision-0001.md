# Decision 0001 — App Architecture & Theme (Locked)

**Status:** Accepted  
**Date:** 2025-09-03  
**Owner:** Product (MentorIQ) + Eng (Claude Code)  
**Related:** /docs/product_vision.md, /docs/roadmap.md, /docs/prd_mentor_assistant.md, /docs/ux_wireframes.md, /CLAUDE.md

---

## 1) Context

We’re building **FLL Mentor Copilot**: an AI-first web app for mentors (Phase 1 = Mentor Assistant). We need to lock the baseline architecture and UI theme so we can implement small, testable slices and scale quickly.

---

## 2) Decision (What we’re locking)

### Frontend & Runtime

- **Framework:** Next.js (App Router) + **TypeScript**
- **Styling:** Tailwind CSS
- **UI Library:** **shadcn/ui** with **dark theme** (tokens live in `CLAUDE.md` + `/docs/ux_wireframes.md`)
- **Icons:** lucide-react
- **Forms:** React Hook Form + Zod (schema validation)

### Authentication & Session

- **Auth Provider:** **Clerk**
- Email/password + OAuth (Google/Microsoft/GitHub)
- Session persistence via Clerk; server-side guards on API routes

### Data & Persistence

- **ORM:** Prisma
- **Dev DB:** SQLite (simple, file-based)
- **Prod DB:** Postgres (managed; Vercel Postgres, Neon, or RDS)
- **Initial Models:**
  - `User` (from Clerk, mirrored minimal profile)
  - `SeasonPlan` (ownerId FK → User)
  - `Agenda` (FK → SeasonPlan; weekNo, blocks)
  - `EmailDraft` (FK → SeasonPlan; weekNo, subject, body)
  - `RubricFeedback` (ownerId; payload, rubricAreas, createdAt)

### API & Boundaries

- **API Surface:** Next.js Route Handlers (`/api/*`)
- **Pattern:** tRPC or REST (start with REST for clarity)
- **Contracts:** Zod-validated DTOs; typed responses

### Testing & Quality

- **Unit:** Vitest
- **Component:** React Testing Library
- **Integration:** Next.js route handlers + Prisma test db
- **E2E:** Playwright
- **Coverage:** ≥80% lines on changed files (CI gate)
- **CI:** GitHub Actions (typecheck, lint, format, unit/RTL/integration/E2E, build, audit)

### Deployment

- **Target:** Vercel (Next.js-native)
- **Pipelines:** PR checks; main → staging + smoke; tags `v*` → prod + post-deploy checks

### Observability & Security (Phase 1 scope)

- **Logging:** Next.js default + console shipping to platform logs
- **Error tracking:** (Phase 1.5) Sentry
- **Secrets:** `.env` (local), encrypted repo or Vercel env vars (prod)
- **Data isolation:** all CRUD scoped by `userId` from Clerk

### UI Theme (Dark) — Tokens (canonical source = `CLAUDE.md`)

- **App BG:** `#0F172A` (slate-900)
- **Card BG:** `#1E293B` (slate-800)
- **Primary:** `#3B82F6` hover `#2563EB`
- **Accent:** `#F97316`
- **Text:** headings `#F8FAFC`, body `#CBD5E1`, muted `#64748B`
- **Shapes:** cards `rounded-2xl shadow-lg border-slate-700`; inputs `rounded-lg bg-slate-900 border-slate-700 text-slate-50`

---

## 3) Rationale

- **Speed + maintainability:** Next.js + shadcn/ui + Tailwind accelerates UI without bespoke component work.
- **Auth done right:** Clerk provides secure, low-effort auth + UI.
- **Predictable data:** Prisma across SQLite (dev) and Postgres (prod) keeps parity.
- **AI-accelerated dev:** Clear boundaries (typed DTOs, tests) keep Claude Code safe and productive.
- **Theming upfront:** locking dark tokens avoids rework and ensures consistent look during MVP.

---

## 4) Alternatives Considered

- **Remix**: great DX, but team and hosting optimized for Next.js.
- **tRPC-first**: nice DX; we’ll start REST for clarity and add tRPC later if needed.
- **Auth.js**: flexible, but Clerk reduces custom logic and speeds delivery.
- **MongoDB**: schemaless okay, but Prisma + Postgres fits our relational needs (plans, agendas).

---

## 5) Consequences (What this enables/limits)

**Enables**

- Rapid scaffold of mentor flows using shadcn components
- Clean auth & per-user data partitioning
- CI gates aligned with our testing pyramid
- Straightforward deploys + previews on Vercel

**Limits / Trade-offs**

- Tighter coupling to Vercel features
- Need to maintain Zod schemas for all API I/O
- Dark theme requires consistent component theming (no “unstyled” stragglers)

---

## 6) Implementation Notes

- Initialize shadcn with dark theme tokens first; create base `ThemeProvider`.
- Gate all `/api/*` with Clerk middleware; add a server util `requireUser()` for route handlers.
- Prisma: create seed scripts and separate test DB; add `prisma migrate dev` to CI.
- Create generators for artifacts (plan, agenda, comms) as **pure functions** → easy to unit test.
- Add Playwright smoke suite for **login → dashboard → generate plan → save agenda**.

---

## 7) Rollback Plan

- If Vercel limits block us, deploy to Fly.io or Railway with minimal Next config changes.
- If Clerk becomes a blocker, swap to Auth.js (keep user table minimal; abstract auth guards).

---

## 8) Validation

- **Definition of Done (architecture):** first vertical slice runs: login → dashboard → create season plan → save agenda; unit/RTL/integration/E2E green in CI; dark theme applied.

---

## 9) Change Log

- **v1 (2025-09-03):** Initial acceptance (this document).

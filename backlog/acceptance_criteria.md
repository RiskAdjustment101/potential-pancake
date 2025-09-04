# Acceptance Criteria — Mentor Assistant (Phase 1)

## Authentication & Persistence

- [ ] Mentor can register using Clerk (email/password or OAuth).
- [ ] Mentor can log in and see a personalized dashboard with saved season plan(s).
- [ ] Mentor data is stored securely and only accessible to the authenticated user.
- [ ] Sessions persist until logout (no forced re-login within 7 days).
- [ ] Password reset flow works (via Clerk).
- [ ] Logging out clears access.

## Season Planner

- [ ] Mentor can input team size, meeting frequency, meeting length, season start, and event date.
- [ ] A 12–16 week season plan is generated automatically.
- [ ] Mentor can regenerate plan if inputs change.
- [ ] Plan persists under mentor account (visible on login).
- [ ] Unit tests validate generation logic (event date alignment, week count).

## Weekly Agendas

- [ ] Mentor can select a week and generate a 60–90 min agenda (warmup, build, code, reflection).
- [ ] Agenda matches that week’s goals from the season plan.
- [ ] Mentor can edit agenda text before saving.
- [ ] Agenda persists to mentor account.
- [ ] At least one E2E test confirms agenda generation works end-to-end.

## Parent Comms

- [ ] Mentor can generate a parent email with upcoming dates + supply needs.
- [ ] Email is formatted in plain text/markdown.
- [ ] Mentor can copy-paste email easily.
- [ ] Email persists to mentor account (history viewable).

## Rubric Feedback

- [ ] Mentor can paste code or text snippet into a form.
- [ ] System returns rubric-aligned feedback in format:  
       `Rubric Area → Current Status → Specific Improvement → Concrete Example`.
- [ ] Feedback is stored with timestamp under mentor account.
- [ ] Unit tests confirm rubric areas map correctly.

## Ops Support

- [ ] Mentor can generate a supply checklist for early/mid/late season.
- [ ] Mentor can generate a run-of-show checklist for competition day.
- [ ] Both checklists are stored under mentor account.

---

# Stretch (Phase 2 Candidates)

## Class Engine

- [ ] Mentor can create a class, enroll students, and view attendance logs.
- [ ] Mentor can document a session (date, activities, notes).
- [ ] Student portfolios generate automatically from documented sessions.

## Marketplace

- [ ] Mentor can browse community-shared resources.
- [ ] Mentor can upload/share their own resource with metadata.
- [ ] Resources have a basic rating or feedback system.

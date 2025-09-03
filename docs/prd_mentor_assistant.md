# PRD — Mentor Assistant (Phase 1 MVP)

## 1. Overview

The Mentor Assistant is the **core Phase 1 feature** of FLL Mentor Copilot.  
It provides parent mentors and teachers with **structured, FLL-specific support** to reduce prep time, increase confidence, and align activities with official rubrics.  

This feature is the **foundation of the product vision** and directly delivers on the roadmap’s Phase 1 milestones.  

---

## 2. Goals & Non-Goals

### Goals
- ✅ Reduce mentor prep time by at least 50%.  
- ✅ Provide a **12–16 week season plan** aligned with team schedule and event date.  
- ✅ Auto-generate **weekly agendas** and **parent comms**.  
- ✅ Offer **rubric-aligned feedback** on code/project snippets.  
- ✅ Supply **operational checklists** (supplies, run-of-show).  

### Non-Goals
- ❌ Full student LMS (covered in Class Engine, Phase 2).  
- ❌ Multi-team management (Phase 3).  
- ❌ Marketplace/community features (Phase 2+).  
- ❌ Advanced image-based robot design feedback (Phase 3).  

---

## 3. User Stories

- *As a mentor, I want to generate a 12–16 week season plan so I know what to cover each session.*  
- *As a mentor, I want ready-to-send parent emails so I can communicate quickly without rewriting.*  
- *As a mentor, I want weekly agendas so I can run efficient and engaging meetings.*  
- *As a mentor, I want to paste a code snippet and get rubric-aligned feedback so students can improve their work.*  
- *As a mentor, I want a supply checklist so I don’t miss essentials before sessions.*  
- *As a mentor, I want a run-of-show guide so competition day is less stressful.*  

### Authentication

- *As a mentor, I want to create an account with email/password (or OAuth via Google) so that I can access my team’s data securely.*   
- *As a mentor, I want to log in and see my saved season plan so that I can pick up where I left off.*   
- *As a mentor, I want my data stored securely so that only I (and optionally co-mentors I invite) can view/edit it.*   
- *As a mentor, I want to reset my password so that I can recover access if needed.*   


---

## 4. Functional Requirements


### Authentication & Persistence
- Use **Clerk.dev** for mentor account management.  
- Must support: account creation, login/logout, password reset, session handling.  
- Tie generated artifacts (season plan, agendas, comms, checklists) to authenticated mentor account.  
- User dashboard displays saved plans and artifacts on login.  

### Season Planner
- Inputs: team size, meeting frequency, meeting length, season start, event date, division, hardware.  
- Output: structured plan (12–16 weeks) with weekly goals.  
- Must allow regeneration if inputs change.  

### Agenda Generator
- 60–90 minute agenda template: warmup, build, code, reflection.  
- Must adapt to chosen week’s goals.  
- Editable by mentor before finalizing.  

### Comms Templates
- Parent-facing emails with:  
  - Upcoming dates  
  - Supply needs  
  - Student commitments  
- Output: plain text + markdown copyable.  

### Rubric Feedback
- Input: text/code snippet.  
- Output: rubric-aligned feedback (Core Values, Innovation Project, Robot Design).  
- Format: “Rubric Area → Current Status → Specific Improvement → Concrete Example.”  

### Ops Support
- Supply checklist: common items per season stage.  
- Run-of-show template for competition day.  

---

## 5. UX Flows / Wireframes (stub)

1. **Mentor Setup**  
   - Fill inputs (team size, frequency, event date).  
   - Generate season plan.  

2. **Weekly Workflow**  
   - Select a week → agenda generated.  
   - Option to generate parent comms + supply list.  

3. **Code/Project Support**  
   - Paste snippet → receive rubric-aligned feedback.  

4. **Competition Prep**  
   - Generate run-of-show checklist.  

(*Detailed sketches to follow in `/docs/ux_wireframes.md`.*)  

---

## 6. Open Questions

- Should plans/agendas be **editable in-app** or only regenerated?  
- Should rubric feedback include **inline code annotations** or just narrative comments?  
- Do we need **calendar export (ICS, Google Calendar)** in MVP?  
- Should we store generated artifacts in a **team dashboard** from the start, or allow local-only?  

---

## 7. Dependencies

- **FLL rubrics (official)** — must not misrepresent; align feedback with published criteria.  
- **Email/comms delivery** — MVP will stop at text export (no email integration).  
- **Persistence** — requires DB for saving plans/agendas/snippets.  
- **Testing** — unit (planner logic), integration (API), E2E (mentor workflow).  

---

## 8. Acceptance Criteria (Phase 1 Done)

- Mentor can generate a season plan in <5 minutes.  
- Mentor can produce an agenda + parent email for any week.  
- Mentor can paste a code snippet and get rubric-aligned feedback.  
- Mentor can export a supply checklist.  
- All features tested (unit + E2E) and run in CI.  
- Docs updated (`CLAUDE.md`, `/docs/product_vision.md`, `/docs/roadmap.md`).  

---

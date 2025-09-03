# /update-docs

Keep documentation aligned with code changes.

## Steps

1. Review changes merged in the branch.
2. Summarize key decisions (architecture, API, UI tokens, dependencies).
3. Update the relevant files in `/docs/*` and `CLAUDE.md`.
   - Product changes → `/docs/product_vision.md`, `/docs/roadmap.md`, PRDs.
   - UX changes → `/docs/ux_wireframes.md`.
   - Repo rituals → `CLAUDE.md`.
4. Update `.claude/decisions/` with a new `decision-XXXX.md` if a new long-term choice was made.
5. Ask: "Do you want me to open a PR with updated docs?"

## Scope

- Focus on **accuracy and traceability**.
- Do not rewrite history; append changes clearly.
- Keep docs concise so they remain mentor-friendly.

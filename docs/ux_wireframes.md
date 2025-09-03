# UX Wireframes — Mentor Assistant

## 🎨 Design Theme (from Discovery)

- **Backgrounds**
  - App shell: `#0F172A` (slate-900)
  - Surface / Cards: `#1E293B` (slate-800)

- **Primary Action Color**
  - Primary Blue: `#3B82F6` (blue-500)
  - Hover/Active: `#2563EB` (blue-600)

- **Accent Color**
  - Orange: `#F97316` (orange-500) — highlights, badges

- **Text**
  - Headings: `#F8FAFC` (slate-50)
  - Body: `#CBD5E1` (slate-300)
  - Muted/Labels: `#64748B` (slate-400)

- **Typography**
  - Headings: `font-semibold`, tracking-tight, `text-lg` to `text-2xl`
  - Body: `font-normal`, `text-base`
  - Small labels: `text-sm`, `uppercase`, `tracking-wide`

- **Components**
  - Cards: `rounded-2xl`, `shadow-lg`, background `slate-800`, border `slate-700`
  - Buttons:
    - Primary: solid `blue-500` with white text
    - Secondary: outline `slate-400`
  - Inputs: `rounded-lg`, background `slate-900`, border `slate-700`, text `slate-50`

- **Icons**
  - Source: `lucide-react`
  - Color: match text (`slate-300`), hover `blue-500`

---

## 1. Authentication Flow (Clerk + shadcn/ui)

**Layout:**

- `<Card>` centered on dark background.
- Inputs styled per dark theme tokens.
- OAuth buttons with outline style, icons.

**Components Used:**

- `Card`, `CardHeader`, `CardContent`
- `Input`, `Label`
- `Button`
- `Separator`

---

## 2. Mentor Dashboard

**Layout:**

- Sidebar (`NavigationMenu`) with dark shell background.
- Content cards on `slate-800` surfaces.
- Recent items displayed in `Table` with hover states.

**Components Used:**

- `NavigationMenu`
- `Card`
- `Table`
- `Badge`

---

## 3. Season Plan Form

**Layout:**

- Form inside dark `Card`.
- Inputs styled for dark background.
- Submit button primary blue.

**Components Used:**

- `Form`, `Input`, `Select`, `Calendar`, `Button`

---

## 4. Agenda Display

**Layout:**

- Agenda items inside `Accordion` with slate backgrounds.
- Editable text areas (`Textarea`) with dark styling.
- Actions at bottom: Save, Generate Parent Email.

**Components Used:**

- `Accordion`
- `Textarea`
- `Button`

---

## 5. Parent Comms

**Layout:**

- Draft email in `Card`.
- Copy-to-clipboard primary button.
- Option to export `.md`.

**Components Used:**

- `Card`
- `Textarea`
- `Button`

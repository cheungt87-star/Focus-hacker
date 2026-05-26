# Analytics Screen — Feature Requirements

## Overview

Add a new **Analytics** section to the app sidebar. It displays a full log of all focus sessions, organised by month, with summary stats and sorting controls.

---

## Sidebar

Add "Analytics" as a new nav item in the sidebar, slotted between Blocked Items and Settings. Use a bar chart SF Symbol. Selecting it loads the Analytics detail view.

---

## Layout

The view has four sections stacked vertically:

1. Page title and subtitle
2. Summary stat cards
3. Controls row (month navigator + sort options)
4. Session log table

---

## Summary stat cards

Four cards in a horizontal row, each showing a single metric for the currently selected month:

- **Sessions** — total number of sessions (complete + abandoned)
- **Focus time** — sum of focus minutes across all sessions, formatted as `Xh Ym`
- **XP earned** — total XP awarded across all sessions
- **Completion** — percentage of sessions that were completed (not abandoned), with a sub-label showing e.g. "15 of 18 finished"

Cards use the existing stat card style from the design system. Colour the values using the established palette — blue for session count, mint for focus time, gold for XP, ember red for completion rate.

---

## Controls row

### Month navigator

A left/right chevron control with the current month and year displayed in the centre (e.g. "May 2026"). Tapping the chevrons moves one month backward or forward. The forward chevron is disabled when the user is already on the current calendar month.

### Sort controls

Three sort chips to the right of the month navigator:

- Date
- Focus time
- XP gained

Only one chip is active at a time. Active chip is highlighted in power blue. Alongside the chips, a direction toggle button shows "Newest first" / "Oldest first" for Date, and "Highest first" / "Lowest first" for Focus time and XP.

---

## Session log table

### Columns (left to right)

| Column | Notes |
|---|---|
| Date | Formatted as `MON 25/05/26` — day abbreviation uppercased, numeric date. Monospaced font, slightly muted. |
| Started | Time session started, `HH:mm` format. Monospaced. |
| Ended | Time session ended, `HH:mm` format. Monospaced. |
| Status | Badge — "Complete" (mint green) or "Abandoned" (ember red), with a checkmark or X icon. |
| Focus time | Right-aligned. Formatted as `Xh Ym` or `Ym`. Monospaced. |
| XP | Right-aligned. Gold star icon + number. If 0 (abandoned), render at low opacity. |

### Row behaviour

- Abandoned sessions have a faint red background tint at rest.
- Tapping a row highlights it — complete sessions highlight in faint blue, abandoned sessions in faint red (stronger than the at-rest tint).
- Tapping the same row again deselects it.
- Rows do not expand on tap.

### Grouping

No date group headers. The Date column handles date context inline. Multiple sessions on the same day naturally repeat the date in the column.

### Empty state

If no sessions exist for the selected month, show a centred message: "No sessions recorded this month."

---

## Data & filtering

- Pull all sessions from the local SwiftData store.
- Filter to the selected month client-side.
- Stat cards update automatically to reflect the filtered month.
- Abandoned = a session where the user ended early and received 0 XP.
- Complete = a session that ran to its natural conclusion.

---

## Design

Follow the existing FocusHacker design system throughout — dark charcoal backgrounds, existing colour tokens, monospaced font for all times and numbers, consistent border radius and spacing with the rest of the app.

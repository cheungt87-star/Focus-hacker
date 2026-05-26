# Analytics Screen — UI Fix Prompt

## Fix 1: Stat cards must be equal width

The four stat cards (Sessions, Focus Time, XP Earned, Completion) must be **exactly equal width** regardless of window or viewport size.

- Use a fixed `maxWidth: .infinity` with a `frame(maxWidth: .infinity)` on each card inside an `HStack` — but critically, also set `frame(minWidth: 0)` so no card can grow wider than its siblings.
- Do **not** size cards based on their content. All four cards must be the same width at all times.
- "Focus Time" is currently truncating to "4h 3..." because its card is narrower. Equal sizing will fix this, but also ensure the value text does not truncate — use `.lineLimit(1)` and `.minimumScaleFactor(0.8)` on the value label as a fallback.
- The `HStack` containing the cards should use a fixed `spacing` (e.g. 10) and fill the full available width.

## Fix 2: Reduce the gap between Status and Focus time columns

There is too much horizontal space between the Status badge and the Focus time column. Fix this by:

- Reducing the width allocated to the Status column. The badge content ("Complete" / "Abandoned") doesn't need more than around 110–120pt.
- Do **not** use `Spacer()` between Status and Focus time. Instead, use fixed-width column frames for every column so spacing is predictable and tight.
- The table columns from left to right should use fixed widths that leave no large empty gap. A suggested column width allocation (adjust to fit your layout):
  - Date: 130pt
  - Started: 65pt
  - Ended: 65pt
  - Status: 115pt
  - Focus time: 90pt (right-aligned)
  - XP: 65pt (right-aligned)
- Any remaining space in the row can sit after the XP column (trailing edge), not between Status and Focus time.

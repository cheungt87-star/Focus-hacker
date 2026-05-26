# FocusHacker — Profile Card Component
## Feature Specification

**Feature:** Profile Card UI  
**Project:** FocusHacker  
**Status:** Ready for implementation  
**Last updated:** 2026-05-25

---

## 1. Overview

The Profile Card is the primary identity and progress surface in FocusHacker. It communicates the user's current level, XP progress, streaks, and lifetime stats in a single compact component. The card must feel motivating — the right panel is designed to celebrate the user's current achievement level, not just display it.

---

## 2. Layout

The card is a two-column layout:

- **Left panel** — identity, stats, XP progress bar
- **Right panel** — 3D level badge, level name, pip progress, next-level CTA

### 2.1 Two-column grid

```
┌─────────────────────────────┬──────────────────┐
│  Identity                   │                  │
│  ─────────────────────────  │   Level Badge    │
│  Stats (3 tiles)            │   Level Name     │
│  ─────────────────────────  │   Pips (x / 10)  │
│  XP Progress bar            │   Next Level →   │
└─────────────────────────────┴──────────────────┘
```

- Left panel: `flex: 1`  
- Right panel: fixed at `210px` on desktop  
- Gap between panels: `0` (panels are visually separated by background colour contrast — left `#1c1c1e`, right `#111`)

---

## 3. Dynamic Sizing (Responsive)

The card must render correctly at **all viewport widths**. It must never clip, overflow, or break layout.

### Breakpoints

| Viewport | Layout |
|---|---|
| ≥ 600px | Two-column (default, as described above) |
| < 600px | Single column — badge panel stacks below the left panel |

### Responsive rules

- Use `min-width: 0` on all flex/grid children to prevent overflow
- All text must truncate gracefully — never overflow its container
- Stat tile values must use fluid font scaling: clamp between `15px` (min) and `20px` (max)
- The badge scales with the right panel: target size is `88px` diameter on desktop, `72px` on mobile
- XP amount label (`61 / 1,000 (6%)`) should truncate on very narrow viewports — never wrap onto two lines. Use `white-space: nowrap; overflow: hidden; text-overflow: ellipsis`
- Stat tile labels use `font-size: 10–11px` and must not wrap — use `overflow: hidden; text-overflow: ellipsis; white-space: nowrap`
- The pip row must wrap cleanly if space is constrained — use `flex-wrap: wrap`

---

## 4. Left Panel

### 4.1 Identity

- **Display name** — `font-size: 20px`, `font-weight: 500`, colour `#fff`
- **Handle** — `@username`, `font-size: 13px`, colour `#555`, `margin-top: 3px`

### 4.2 Stat Tiles

Three equal-width tiles in a horizontal row with `gap: 8px`. Each tile: `background: #252527`, `border-radius: 10px`, `padding: 10px 12px`.

| Tile | Label | Icon | Value |
|---|---|---|---|
| 1 | Lifetime XP | `trending-up` | Total accumulated XP (integer) |
| 2 | Best streak | `flame` | Longest consecutive week streak (e.g. `4 wks`) |
| 3 | Lifetime sessions | `layout-list` | Total completed focus sessions (integer) |

- Label: `font-size: 10–11px`, colour `#555`, displayed above the value with a leading icon
- Value: `font-size: 19px`, `font-weight: 500`, colour `#fff`

### 4.3 XP Progress Bar

Displayed below the stat tiles.

**Header row** (space-between):
- Left: `"Progress to [Next Level Name]"` — `font-size: 12px`, `font-weight: 500`, colour `#aaa`
- Right: `"[currentXP] / [targetXP] ([pct]%)"` — `font-size: 12px`, `font-weight: 500`, coloured with the level's accent colour

**Bar:**
- Track: `background: #252527`, `border-radius: 99px`, `height: 7px`
- Fill: `border-radius: 99px`, `height: 7px`, background set to the level's accent colour, width = `(currentXP / targetXP) * 100%`
- Fill width must be clamped: minimum `2%` (so the bar is never invisible at zero), maximum `100%`

**XP formatting:**
- Values ≥ 1,000 must display with comma separator (e.g. `1,000`, `12,500`)
- Percentage is `Math.round((currentXP / targetXP) * 100)`

**Max level edge case:**
- When the user is at Level 10 (GOAT), the label reads `"Max level reached"` and the value shows total XP only (no target or percentage). The bar is full (100%).

---

## 5. Right Panel — Level Badge

### 5.1 Panel

- Background: `#111` with a full-bleed level gradient overlay at ~25% opacity (same three stops and angle as the badge face) to tint the panel with the current level's colours
- Leading edge: 1px vertical divider in the level's border colour at ~35% opacity (desktop two-column layout only)
- Content centred vertically and horizontally
- `padding: 24px 16px`

### 5.2 3D Badge

The badge is a layered circle stack that creates a raised, dimensional appearance.

```
[Outer shadow ring]       88px   background: #0a0a0a
  [Mid depth ring]        76px   background: #1a1a1a, inset shadow
    [Badge face]          64px   gradient background (level colour)
      [Shine overlay]            top-left highlight: rgba(255,255,255,0.22), 22×16px ellipse
      [Bottom shadow]            lower half darkening: rgba(0,0,0,0.28)
      [Icon]                     centred, Tabler icon, colour per level
```

**Layering detail:**

1. **Outer ring** — `border-radius: 50%`, solid dark fill (`#0a0a0a`), no border. Acts as the drop-shadow/depth base.
2. **Mid ring** — `border-radius: 50%`, slightly lighter dark fill (`#1a1a1a`), with `box-shadow: inset 0 2px 4px rgba(255,255,255,0.05), inset 0 -2px 4px rgba(0,0,0,0.5)` to simulate the curved edge catching light.
3. **Badge face** — `border-radius: 50%`, `overflow: hidden`, background is a `linear-gradient(145deg, [light], [mid], [dark])` using the level's three colour stops (see Section 7). `box-shadow: inset 0 -3px 8px rgba(0,0,0,0.4)` on the face adds lower-edge depth.
4. **Shine spot** — `position: absolute`, `top: 5px`, `left: 9px`, `width: 22px`, `height: 16px`, `border-radius: 50%`, `background: rgba(255,255,255,0.22)`. Simulates a light source from top-left.
5. **Bottom shadow** — `position: absolute`, `bottom: 0`, full width, `height: 30px`, `background: rgba(0,0,0,0.28)`, rounded bottom. Adds depth to the lower face.
6. **Icon** — centred, `z-index: 1`, `font-size: 26px`, colour per level (see Section 7).

### 5.3 Level Name & Number

- **Level name** — `font-size: 15px`, `font-weight: 500`, colour `#fff`, text-align centre
- **Level number** — `font-size: 11px`, colour `#555`, text-align centre, format: `"Level [N] · [position] / 10"` (e.g. `"Level 1 · 1 / 10"`)

### 5.4 Pip Progress Indicator

A row of 10 pills showing how many levels have been unlocked.

- Each pip: `height: 4px`, `width: 14px`, `border-radius: 99px`
- Gap between pips: `3px`
- Filled pips (up to current level index): level accent colour
- Unfilled pips: `#252527`
- Row wraps if the panel is too narrow (`flex-wrap: wrap`)
- The number of filled pips equals the user's current level position (1 = Newcomer, 2 = Rookie, ... 10 = Legend, 11 = GOAT)

### 5.5 Next Level Pill

- Format: `"Next: [Next Level Name] →"`
- `font-size: 11px`, `border-radius: 20px`, `padding: 3px 10px`
- Background, border, and text colour sourced from the level's pill colour tokens (see Section 7)
- Hidden (`display: none`) when the user is at GOAT (max level)

---

## 6. Data Model

| Property | Type | Description |
|---|---|---|
| `displayName` | `string` | User's display name |
| `handle` | `string` | Username with `@` prefix |
| `lifetimeXP` | `number` | Total XP earned |
| `bestStreak` | `number` | Longest streak in weeks |
| `lifetimeSessions` | `number` | Total completed sessions |
| `currentLevel` | `number` | Index 0–10 (0 = Newcomer, 10 = GOAT) |
| `currentLevelXP` | `number` | XP within the current level tier |
| `nextLevelXP` | `number \| null` | XP required to reach next level (null at GOAT) |

---

## 7. Level Colour System

Each level has a defined colour token set. All colours are applied consistently across the badge, XP bar, pips, and next-level pill.

| Level | Name | Badge gradient (145deg) | Accent | Icon colour | Pill bg | Pill border | Pill text | Icon |
|---|---|---|---|---|---|---|---|---|
| 0 | Newcomer | `#25a876 → #1db97c → #0f8a5a` | `#1db97c` | `rgba(255,255,255,0.92)` | `rgba(29,185,124,0.10)` | `rgba(29,185,124,0.25)` | `#1db97c` | `sparkles` |
| 1 | Rookie | `#bfdbfe → #93c5fd → #3b82f6` | `#60a5fa` | `#1e3a8a` | `rgba(59,130,246,0.12)` | `rgba(59,130,246,0.30)` | `#60a5fa` | `trophy` |
| 2 | Amateur | `#bbf7d0 → #86efac → #22c55e` | `#4ade80` | `#14532d` | `rgba(34,197,94,0.12)` | `rgba(34,197,94,0.30)` | `#4ade80` | `star` |
| 3 | Semi-Pro | `#dd6f1f → #c4730a → #8b4513` | `#dd6f1f` | `rgba(255,220,180,0.90)` | `rgba(221,111,31,0.12)` | `rgba(221,111,31,0.30)` | `#dd6f1f` | `medal` |
| 4 | Professional | `#f5f5f5 → #d3d3d3 → #a9a9a9` | `#a9a9a9` | `#2a2a2a` | `rgba(169,169,169,0.12)` | `rgba(169,169,169,0.30)` | `#aaaaaa` | `briefcase` |
| 5 | All-Star | `#ffd700 → #ffed4e → #daa520` | `#ffd700` | `#4a3500` | `rgba(255,215,0,0.12)` | `rgba(255,215,0,0.30)` | `#daa520` | `crown` |
| 6 | Champion | `#f0f0f0 → #e0e0e0 → #b0b8c0` | `#b0b8c0` | `#1a2030` | `rgba(176,184,192,0.12)` | `rgba(176,184,192,0.30)` | `#8090a8` | `shield` |
| 7 | Elite | `#1e3a8a → #1d4ed8 → #0891b2` | `#38bdf8` | `rgba(186,230,253,0.92)` | `rgba(56,189,248,0.10)` | `rgba(56,189,248,0.30)` | `#38bdf8` | `diamond` |
| 8 | Hall of Famer | `#14532d → #15803d → #059669` | `#34d399` | `rgba(167,243,208,0.92)` | `rgba(52,211,153,0.10)` | `rgba(52,211,153,0.30)` | `#34d399` | `certificate` |
| 9 | Legend | `#7f1d1d → #991b1b → #be123c` | `#fb7185` | `rgba(254,205,211,0.92)` | `rgba(251,113,133,0.10)` | `rgba(251,113,133,0.30)` | `#fb7185` | `flame` |
| 10 | GOAT | `#020617 → #0f172a → #1e293b` | `#fbbf24` | `rgba(253,224,71,0.95)` | `rgba(251,191,36,0.12)` | `rgba(251,191,36,0.40)` | `#fbbf24` | `crown` |

**Badge ring colours** (outer and mid) are always dark and level-agnostic:
- Outer ring: `#0a0a0a`
- Mid ring: `#1a1a1a`

---

## 8. XP Thresholds

| Level | Name | XP required (cumulative) |
|---|---|---|
| 0 | Newcomer | 0 |
| 1 | Rookie | 1,000 |
| 2 | Amateur | 3,000 |
| 3 | Semi-Pro | 6,000 |
| 4 | Professional | 12,000 |
| 5 | All-Star | 22,000 |
| 6 | Champion | 36,000 |
| 7 | Elite | 56,000 |
| 8 | Hall of Famer | 84,000 |
| 9 | Legend | 124,000 |
| 10 | GOAT | 184,000 |

---

## 9. Requirements

### P0 — Must ship

- [ ] Two-column card layout with left stats panel and right badge panel
- [ ] Identity section: display name + handle
- [ ] Three stat tiles: Lifetime XP, Best streak, Lifetime sessions
- [ ] XP progress bar labelled `"Progress to [Next Level]"`
- [ ] XP amount displayed as `"[x] / [target] ([pct]%)"` with comma formatting on values ≥ 1,000
- [ ] Progress bar fill coloured with level accent colour
- [ ] Right panel background: `#111` with level gradient overlay at ~25% opacity
- [ ] 3D badge with five-layer stack: outer ring, mid ring, face gradient, shine spot, bottom shadow
- [ ] Badge gradient, icon, and icon colour sourced from the level colour token table
- [ ] Level name and level number displayed below the badge
- [ ] 10 pips showing current level position, filled with accent colour
- [ ] Next-level pill with level-specific colours; hidden at GOAT
- [ ] Responsive single-column layout below 600px viewport width
- [ ] All text truncates gracefully — no overflow, no horizontal scroll
- [ ] Stat tile values use `clamp(15px, 2vw, 20px)` font-size
- [ ] Badge scales: 88px on desktop, 72px on mobile

### P1 — Nice to have

- [ ] Animated XP fill bar on mount (CSS transition, ~500ms ease)
- [ ] Level-up transition: brief scale + glow animation on the badge when level changes
- [ ] Tooltip on each stat tile with a short explanation on hover/long-press
- [ ] Tapping the badge on mobile shows a full-screen level detail overlay

### P2 — Future consideration

- [ ] Shareable profile card image export
- [ ] Animated particle effect on GOAT badge
- [x] App light/dark appearance — hero card stays a dark island; light mode only adjusts outer border/shadow on the page

---

## 10. Acceptance Criteria

### Layout
- Given any viewport ≥ 600px wide, the card renders in two columns with no overflow
- Given any viewport < 600px wide, the badge panel stacks below the left panel
- Given a very long display name, the name truncates with ellipsis rather than pushing layout

### XP progress
- Given a user with 61 XP targeting 1,000 XP, the label reads `"Progress to Rookie"`, the amount reads `"61 / 1,000 (6%)"`, and the bar fill is 6.1% wide
- Given a user at exactly 1,000 XP, they are promoted to Rookie and the bar resets to 0% against the next target
- Given a GOAT user, the progress label reads `"Max level reached"`, no target is shown, and the bar is full

### Badge
- Given a Newcomer user, the badge renders with green gradient `#25a876 → #1db97c → #0f8a5a` and a sparkles icon in white
- Given a GOAT user, the badge renders with dark gradient `#020617 → #0f172a → #1e293b` and a crown icon in gold
- The shine spot is always visible in the upper-left quadrant of the badge face regardless of level
- The pip row shows exactly N filled pips where N = current level index + 1 (Newcomer = 1 filled)

### Responsive
- Given a 375px viewport, all content is visible with no horizontal scrolling
- Given a 375px viewport, the badge and left stats stack vertically in readable order
- Stat tile labels never wrap to two lines at any common viewport width

---

## 11. Open Questions

| Question | Owner | Blocking? |
|---|---|---|
| Should `lifetimeSessions` count only fully completed sessions, or include early-ended ones? | Product | Yes |
| What is the XP for Newcomer → Rookie — is it raw lifetime XP (1,000) or XP earned within the Newcomer tier? | Product | Yes |
| Should the badge animate on first render (entrance animation) or only on level-up events? | Design | No |
| Is Best Streak measured in consecutive weeks or consecutive days? | Product | Yes |

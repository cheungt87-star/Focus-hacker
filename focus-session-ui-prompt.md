# Focus Session Screen — FocusHacker Implementation Spec

SwiftUI / macOS spec for the shared **`FocusSessionScreenView`** used in the menu bar popover and main window Timer section.

---

## Layout

Single-column, vertically stacked, centred. No horizontal scrolling.

| Surface | Max width |
|---|---|
| Menu bar popover | 344pt content (`384pt` panel minus `20pt` padding each side) |
| Main window | 480pt, centred in the Timer section |

Top to bottom:
1. Screen label
2. Preset selector
3. Timer display (up-next label + MM:SS)
4. Cycle counter pill
5. CTA button (+ optional End session when running)
6. Session stats footer

**Outside the card** (do not embed):
- Paywall lock banner
- Completion banner
- Get-ready countdown handling (popover card only; menu bar pill unchanged)
- Create Custom configuration form (`TimerSessionConfigurationForm`) below the card
- Open Focus Hacker / Quit app actions (popover)

---

## Out of scope

Do **not** modify menu bar status item, menu bar pill text, or system transition notifications (`MenuBarStatusLabel`, `menuBarText` / `menuBarPill*` symbols, `TransitionNotificationService`).

---

## SwiftUI implementation

| Piece | Location |
|---|---|
| Shared view | `FocusHacker/Views/AppShell/FocusSessionScreenView.swift` |
| Palette | `FocusHacker/Resources/FocusSessionScreenPalette.swift` — `FocusSessionScreenPalette.resolve(for:)` |
| View-model copy | `focusSession*` properties on `AppShellViewModel` (not `menuBarText` / pill symbols) |
| Layout profiles | `FocusSessionScreenLayout.menuBarPopover` / `.mainWindow` |

Mode switching: `@Environment(\.colorScheme)` plus app `AppearancePreference` via `preferredColorScheme` on popover/main window roots.

---

## Color tokens

Implemented in `FocusSessionScreenPalette`.

### Dark mode
```
bgScreen:       #111316
bgSelector:     #0d1f13
bgCyclePill:    #1a1d22
borderSelector: #4ade80
borderStats:    #1e2128
textTitle:      #f1f5f9
textSubtitle:   #6ee7a0
textLabel:      #666666
textTimer:      #f1f5f9
textUpNext:     #64748b
textStatsLabel: #4a5568
textStatsValue: #64748b
accent:         #4ade80
accentColon:    rgba(74, 222, 128, 0.8)
ctaBackground:  #4ade80
ctaForeground:  #0a1f0d
```

### Light mode
```
bgScreen:       #f8faf8
bgSelector:     #f0faf3
bgCyclePill:    #e8f5ec
borderSelector: #16a34a
borderStats:    #e2e8e2
borderScreen:   #e2e8e2
textTitle:      #1a1a1a
textSubtitle:   #16a34a
textLabel:      #9aa89a
textTimer:      #111827
textUpNext:     #94a3b8
textStatsLabel: #b0bec5
textStatsValue: #94a3b8
accent:         #16a34a
accentColon:    #16a34a
ctaBackground:  #16a34a
ctaForeground:  #ffffff
```

---

## Components

### 1. Screen label
- Text: "Focus session" rendered **uppercase** (`FOCUS SESSION`)
- Font: 12pt, letter-spacing 0.06em, colour `textLabel`
- Centred, margin bottom 14pt

### 2. Preset selector
- Background `bgSelector`, border 1.5pt `borderSelector`, radius 14pt
- Padding 14pt × 16pt, margin bottom 24pt
- Chevrons: `‹` / `›`, 20pt, colour `accent`
- Centre: preset name 17pt weight 500 `textTitle`; subtitle 12pt `textSubtitle`
- **Disabled** (opacity reduced) while a session is running or get-ready is active

**Preset carousel** (Classic → Intense → Expert → Create Custom):

| Name | Focus | Break | Cycles (rounds) |
|---|---|---|---|
| Classic (Recommended) | 25 min | 5 min | 4 |
| Intense | 40 min | 10 min | 3 |
| Expert | 50 min | 10 min | 3 |
| Create Custom | — | — | — |

Subtitle format: `50 min · 10 min break · 3 cycles` (`FocusSessionPreset.carouselDescriptionLine`).

Create Custom reveals `TimerSessionConfigurationForm` below the card (session breaks, total sessions, etc.).

### 3. Timer display
- Up-next line: `UP NEXT · FOCUS` when idle or in focus; `UP NEXT · BREAK` during rest; `GET READY` during get-ready countdown
- 11pt uppercase, letter-spacing 0.08em, colour `textUpNext`
- Timer: MM:SS, 68pt (popover) / 72pt (main window), weight bold, tracking −2
- Digits `textTimer`; colon `accentColon` (split `Text` nodes, not single monolithic string)

### 4. Cycle counter pill
- Capsule, background `bgCyclePill`, padding 5pt × 14pt
- Combined line: `CYCLE` + `1 / 3` (value in `accent`)
- Idle: always `1 / N`; running: current round / total rounds

### 5. CTA button
- Full width, `ctaBackground`, radius 14pt, padding 16pt, 16pt semibold `ctaForeground`
- **Idle:** ▶ Start focus
- **Running:** ⏸ Pause
- **Paused:** ▶ Resume
- **Get-ready:** Cancel (replaces Start)
- **Running secondary:** End session text button below primary CTA

Preset switching while running is blocked (`cycleFocusPreset` guard); no confirmation dialog.

### 6. Session stats footer
- Top border 0.5pt `borderStats`, padding top 14pt
- Three equal columns with vertical dividers

| Idle label | Running label | Value source |
|---|---|---|
| TOTAL | SESSION LEFT | Planned / remaining wall-clock |
| FOCUS | FOCUS LEFT | Planned / remaining focus time |
| SESSIONS | SESSIONS LEFT | `cyclesPerSession` / cycles remaining |

---

## Behaviour

- Timer counts down from configured focus duration
- On 00:00 → audio cue → auto advance to break (existing `TimerService`)
- After break → increment round → return to focus until rounds complete
- After all cycles → completion banner outside card
- Pausing freezes countdown; resume continues
- Switching presets while idle resets staging configuration via `applyFocusPreset`

---

## Tests

- `FocusSessionPresetTests` — carousel description lines
- `FocusSessionScreenTests` — palette tokens, layout width, cycle pill / footer labels via view model

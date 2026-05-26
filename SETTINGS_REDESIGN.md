# FocusHacker Settings Redesign

**Date:** May 25, 2026  
**Status:** Design Proposal  
**Focus:** UX Reorganization, Labeling Clarity, Voice Pack UI Overhaul

---

## Executive Summary

The current settings menu feels scattered and grows organically as features are added. This redesign reorganizes settings into semantic groups, improves label clarity, and redesigns the voice pack selector to show all options inline with preview and select actions.

**Primary Goal:** Make settings discoverable, understandable, and less overwhelming.

---

## Current Problems

1. **Scattered organization** — Appearance, gamification, account settings, sound, and developer options mixed without hierarchy
2. **Unclear "Unknown" status** — Browser permissions show "Unknown" with no explanation of what users should do
3. **Ambiguous sound pack toggle** — Dropdown with Voice Prompts/Chimes doesn't clearly show which is active
4. **Destructive actions buried** — Reset buttons scattered throughout (lifetime XP, all progress, purchases) without visual warning
5. **Vague microcopy** — "Mute transition audio" and numbered displays (10h, 0m) lack context
6. **Inconsistent interaction patterns** — Links mixed with buttons, toggles in unexpected places
7. **No visual hierarchy** — All sections feel equally important when some are "core" and some are "power user"

---

## Proposed Solution

Reorganize settings into **5 semantic sections** based on user mental models, moving from basic (Appearance) to advanced (Data & Privacy).

```
1. APPEARANCE
2. NOTIFICATIONS & SOUND
3. FOCUS SETTINGS
4. PROFILE
5. ADVANCED
```

This approach:
- Groups related settings together
- Separates power-user/destructive actions
- Creates clear visual hierarchy
- Improves discoverability
- Reduces cognitive load

---

## Detailed Section Redesign

### 1. APPEARANCE

**What stays the same:**
- Color theme selector (System / Light / Dark)
- "Show Dock icon" toggle

**Why this section:**
Core visual customization users adjust once and rarely change.

```markdown
# Appearance

## Color Theme
Choose light, dark, or follow macOS system appearance.

[System] [Light] [Dark]
Currently showing: Dark

Applies to the main window and menubar popover. Focus and rest 
session colors stay warm or cool on top of your theme.

## Dock Icon Visibility
Show Dock icon [Toggle: ON]

Control how FocusHacker shows up in the Dock. Turn off for a 
menubar-only presence. While the Dock icon is hidden, macOS 
runs FocusHacker as an accessory app and does not show the app's 
Help menu; use Blocked Items for your lists and Settings → 
Browser blocking for permissions.
```

---

### 2. NOTIFICATIONS & SOUND

**What's new:**
- Renamed from "Sound & notifications" (clearer order)
- Improved label: "Mute Session Transitions"
- Completely redesigned voice pack selector (see section below)
- "Review Notification Preferences" stays but improved

```markdown
# Notifications & Sound

## Mute Session Transitions
[Toggle: OFF]

Silence audio cues between focus and rest periods. When enabled, 
FocusHacker stays quiet even during session changes.

## Voice Pack
Choose how FocusHacker announces session changes.

[Voice Pack Card Grid Layout - See detailed spec below]

## Notification Preferences
[Link: "Review notification preference"]

Customize when macOS shows notifications and sounds for your 
focus sessions.
```

---

### 3. FOCUS SETTINGS

**Renamed from:** "Gamification"

**What's new:**
- Clearer section name (users think "Focus Settings," not "Gamification")
- Better labels with context
- Keep XP display but label clearly

```markdown
# Focus Settings

Hacker goal is 800 minutes per week (Monday–Sunday). Changing 
your personal target resets your personal streak.

## Weekly Focus Target
Current target: 600 min / week

Update your hacker goal. Streaks reset every Sunday.

[Input: 600] minutes per week

## Current Streak
10 hours this week

Next milestone: 50 hours total

You're [X] minutes away from your weekly goal.
```

**Why this works:**
- Explains what the XP/streak system means
- Context for when changes reset
- Shows progress toward goals

---

### 4. PROFILE

**New standalone section** (was buried in original settings)

```markdown
# Profile

Shown at the top of your My Profile page. Stored on this Mac only.

[Input field: Display name]
Test123
```

**Why:**
- Separates account identity from functional settings
- Reduces clutter in appearance section
- Clear what this data is used for

---

### 5. ADVANCED

**New section combining:**
- Browser automation setup (clearer messaging)
- Developer options
- **Danger Zone** for destructive actions with red visual treatment

```markdown
# Advanced Settings & Automation

## Browser Automation
Safari and Chrome blocking runs only during focus sessions.

**Safari**
[Status: Not Connected]

**Google Chrome**
[Status: Not Connected]

[Re-check Browser Permissions] [Open Automation Settings]

Blocking runs only during focus. Manage blocked domains and apps 
under Blocked Items in the sidebar.

---

## 🔴 DANGER ZONE
These actions are permanent and cannot be undone. Proceed carefully.

### Reset Weekly Streak
Clears your current streak and weekly progress. Your lifetime 
stats remain.

[Button: Reset Weekly Streak]

### Reset All Progress
Clears all sessions, XP, streaks, and chart data on this Mac only. 
This action is irreversible.

[Button: Reset All Data]

### Restore Purchases
Reactivate your Lifetime Access license on a new Mac.

[Button: Restore License]
```

**Why this structure:**
- "Not Connected" is clearer than "Unknown"
- Red visual zone for destructive actions
- Context for what each action does
- Warning text prepares users

---

## Voice Pack Selector — Detailed Redesign

### Current State
- Single voice dropdown (hard to preview)
- Toggle between Voice Prompts / Chimes
- No visual feedback on what's currently selected

### Proposed State
**All 5 voice options visible as inline cards** with preview and select buttons.

```markdown
## Voice Pack
Choose how FocusHacker announces session changes.

[Card Layout Grid: 3 columns on desktop, 1 on mobile]

### Card 1: Voice Prompts
Energetic vocal cues for focus and rest transitions.

[Preview Button] [Select Button / Selected Badge]

---

### Card 2: Chimes
Clean, musical bell sounds for session changes.

[Preview Button] [Select Button / Selected Badge]

---

### Card 3: Ambient Bell
Soft, non-intrusive notification tone.

[Preview Button] [Select Button / Selected Badge]

---

### Card 4: Silence
No audio. Visual notifications only (if enabled).

[Preview Button] [Select Button / Selected Badge]

---

### Card 5: Custom (Future)
Create your own notification sound.

[Preview Button] [Select Button / Selected Badge]
(Disabled if not yet implemented)
```

### Visual Specifications

**Card Styling:**
```css
.voice-pack-card {
  Border: 2px solid #e0e0e0;
  Border-radius: 8px;
  Padding: 16px;
  Background: white;
  Text-align: center;
  Cursor: pointer;
  Transition: all 200ms ease;
}

.voice-pack-card:hover {
  Border-color: #3b82f6;
  Box-shadow: 0 4px 12px rgba(59, 130, 246, 0.15);
  Transform: translateY(-2px);
}

.voice-pack-card.selected {
  Border-color: #3b82f6;
  Background-color: #f0f9ff;
}
```

**Button States:**
- **[Preview]** — Secondary button (gray), plays 3–5 second sample
- **[Select]** — Primary button (blue), available when not selected
- **[Selected]** — Green badge, shown instead of button when active

**Grid Layout:**
- **Desktop (1024px+):** 3 columns
- **Tablet (640–1023px):** 2 columns
- **Mobile (<640px):** 1 column

### User Flow

1. User opens Notifications & Sound section
2. Sees 5 voice pack cards arranged in a grid
3. Hovers over a card → slight elevation + border color change
4. Clicks **[Preview]** → plays 3–5 second sample audio
5. Clicks **[Select]** → card updates to show **[Selected]** badge
6. Returns anytime to change packs (no confirmation needed)

**Why this works:**
- All options visible at once = easy comparison
- Preview without committing = low-risk exploration
- Clear current selection = no ambiguity
- Faster interaction than dropdown

---

## Section Organization Map

```
┌─ SETTINGS
│
├─ 1. APPEARANCE (Basic customization)
│  ├─ Color Theme
│  └─ Dock Visibility
│
├─ 2. NOTIFICATIONS & SOUND (Sensory preferences)
│  ├─ Mute Session Transitions
│  ├─ Voice Pack [REDESIGNED]
│  └─ Review Notification Preferences
│
├─ 3. FOCUS SETTINGS (Core feature setup)
│  ├─ Weekly Focus Target
│  └─ Current Streak Display
│
├─ 4. PROFILE (Account identity)
│  └─ Display Name
│
└─ 5. ADVANCED (Power user + destructive)
   ├─ Browser Automation Setup
   └─ 🔴 DANGER ZONE
      ├─ Reset Weekly Streak
      ├─ Reset All Progress
      └─ Restore Purchases
```

---

## Implementation Notes

### No Longer Scattered
**Removed from original locations:**
- "Reset lifetime XP" → Moved to DANGER ZONE
- "About" section → Can stay or move to separate page
- "Developer" section → Merged into ADVANCED

### New Behaviors
- Browser status changes from "Unknown" to "Not Connected" (clearer)
- Streak display includes context ("10 hours this week", "Next milestone: 50 hours")
- Voice pack selection is instant (no confirmation dialog)

### Accessibility Considerations
- All cards keyboard-navigable (Tab to cards, Space/Enter to select)
- Focus indicators clear on each card
- Color not sole indicator (badges and button states provide redundant feedback)
- Preview button accessible via keyboard (Space/Enter plays audio)
- Descriptions provide context for screen readers

---

## Benefits Summary

| Aspect | Before | After |
|--------|--------|-------|
| **Organization** | Scattered by feature | Grouped by user mental model |
| **Discoverability** | Hunt through long list | Find section, then setting |
| **Browser Status** | "Unknown" (confusing) | "Not Connected" (actionable) |
| **Voice Packs** | Dropdown + toggle | 5 visible cards with preview |
| **Destructive Actions** | Buried throughout | Red DANGER ZONE section |
| **Overwhelming** | Yes (mixed importance) | No (clear hierarchy) |
| **Label Clarity** | "Mute transition audio" | "Mute Session Transitions" |

---

## Next Steps

1. **Design mockup** — Create visual prototype of new layout (Figma/design tool)
2. **User testing** — Test discoverability of reorganized sections
3. **Voice pack feedback** — Validate that card layout is faster than dropdown
4. **Accessibility audit** — Verify WCAG AA compliance on all new components
5. **Developer handoff** — Create detailed specs for implementation
6. **QA validation** — Verify new settings structure works in dark/light themes

---

## Revision History

| Version | Date | Author | Notes |
|---------|------|--------|-------|
| 1.0 | 2026-05-25 | Design Review | Initial proposal |


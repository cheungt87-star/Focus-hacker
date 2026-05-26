# Week Progress Component - Implementation Prompt for Cursor

## Overview
Implement a simplified week progress component with:
- **Left**: Week Streak hero (large number)
- **Right**: Two goal rows (Hacker Goal + Personal Goal) with linear progress bars
- **Dual modes**: Focus (ember red, dark bg) and Rest (mint, light bg)
- **Progress bars**: Show min/max minutes AND percentage completion

## Design System (FocusHacker v2.0)

### Colors
```
Focus Mode:
  - Primary: #FF4757 (Ember)
  - Background: #1A1A2E (Charcoal)
  - Card BG: #2D2D44
  - Accent: #FFD700 (Gold)

Rest Mode:
  - Primary: #00D2D3 (Mint)
  - Background: #F5F5F7
  - Card BG: #FFFFFF
  - Accent: #FFD700 (Gold)
```

### Typography
- Font-family: Inter (body), IBM Plex Mono (numbers)
- Weights: 400 (regular), 600 (semibold), 700 (bold)
- Streak number: 80px, monospace, bold
- Labels: 12px uppercase, letter-spacing 1px, 600 weight
- Goal names: 13px, 600 weight

### Spacing
- Card padding: 2rem
- Column gap: 2rem
- Goal rows gap: 1.5rem
- Label-to-bar gap: 0.75rem

## Component Structure

```jsx
<WeekProgress
  hackerGoal={{ completed: 49, total: 800 }}
  personalGoal={{ completed: 49, total: 330 }}
  weekStreak={0}
  mode="focus" // or "rest"
  onModeChange={(mode) => {}}
/>
```

## Key Implementation Details

### 1. Progress Bar Calculation
- Width: `(completed / total) * 100`%
- Background: Linear gradient from primary color to gold (#FFD700)
- Height: 12px
- Border radius: 6px
- Add shimmer animation for visual interest

### 2. Mode Toggle
- Two buttons: "🔴 Focus" and "🌿 Rest"
- Active button shows primary color background
- Clicking toggles between modes
- All colors transition smoothly

### 3. Layout
- CSS Grid: 2 columns (1fr 1fr)
- Left column: centered flex column
- Right column: flex column with gap for goal rows
- Vertical divider: `border-right: 1px solid rgba(255,255,255,0.1)` (focus) or `rgba(0,0,0,0.05)` (rest)

### 4. Progress Calculation
```javascript
const hackerPercent = Math.round((49 / 800) * 100); // 6%
const personalPercent = Math.round((49 / 330) * 100); // 15%
```

### 5. Shimmer Animation
```css
@keyframes shimmer {
  0% { left: -100%; }
  100% { left: 100%; }
}
```
Applied to a gradient overlay on the progress bar fill

## Props

| Prop | Type | Default | Notes |
|------|------|---------|-------|
| `hackerGoal` | `{ completed, total }` | Required | Minutes object |
| `personalGoal` | `{ completed, total }` | Required | Minutes object |
| `weekStreak` | Number | 0 | Consecutive weeks |
| `mode` | 'focus' \| 'rest' | 'focus' | Current theme mode |
| `onModeChange` | Function | - | Callback when mode changes |

## File Structure

```
src/
  components/
    WeekProgress/
      WeekProgress.jsx         # Main component
      weekProgress.module.css  # Styles
      WeekProgress.test.jsx    # Tests (optional)
```

## CSS Classes & Selectors

- `.week-progress-container` - Main wrapper
- `.week-progress-container.mode-focus` - Focus mode styles
- `.week-progress-container.mode-rest` - Rest mode styles
- `.mode-toggle` - Toggle button container
- `.toggle-btn` - Individual toggle button
- `.toggle-btn.active` - Active toggle state
- `.progress-bar` - Goal progress bar container
- `.progress-fill` - Animated fill element
- `.streak-hero` - Week streak display area

## Responsive Behavior

- Desktop (1024px+): Full side-by-side layout
- Tablet (768px-1023px): Stack to column or reduce padding
- Mobile (<768px): Stack full width (stretch layout)

## Accessibility

- Use semantic HTML (buttons, labels)
- Ensure focus indicators visible on toggle buttons
- Color not sole indicator (use labels + numbers)
- Respects `prefers-reduced-motion` (disable shimmer animation)

## Testing Checklist

- [ ] Both modes render correctly (Focus/Rest)
- [ ] Mode toggle switches smoothly
- [ ] Progress bars calculate % correctly
- [ ] Shimmer animation loops smoothly
- [ ] Responsive on mobile (no overflow)
- [ ] Accessibility: keyboard navigation works
- [ ] Numbers are properly formatted (monospace)
- [ ] All text is legible on both backgrounds

## Build Instructions

1. Create component file `WeekProgress.jsx`
2. Create stylesheet `weekProgress.module.css`
3. Copy color tokens from FocusHacker v2.0 design system
4. Implement mode state management (useState or prop-based)
5. Add toggle button click handlers
6. Test both modes and responsive breakpoints
7. Export component for use in dashboard

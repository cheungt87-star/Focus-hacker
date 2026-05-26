# Week Progress Component - Final Design

Build a week progress tracking component with two sections: left (focus tracking) and right (streak indicator).

## Left Section: Focus Time Tracking

### Header
- "Focus time this week" (12px, uppercase, gray-500)

### Accumulated Hours
- Label: "Focus hours so far this week" (11px, uppercase, muted gray)
- Display: Large number (28px bold) + "min" label (13px gray)
- Example: 51 min

### Progress Towards Goals Section
- Subheader: "Progress towards goals" (12px, uppercase, gray-500)
- Spacing: 2rem between sections, 2.5rem between goals

#### Hacker Goal (HERO/PROMINENT)
- Label: 15px, font-weight 500
- Progress bar: 8px height, #2563eb (vibrant blue)
- Metric: "749 min to go" (14px, font-weight 600)
- Percentage: 6% (12px, muted)
- Spacing: 1rem below label

#### Personal Goal (SUBTLE)
- Label: 13px, font-weight 400, gray-600 (muted)
- Progress bar: 5px height, #e9d5ff (very light purple)
- Metric: "729 min to go" (12px, font-weight 400, gray-600)
- Percentage: 7% (11px, muted)
- Spacing: 0.75rem below label

## Right Section: Week Streak

- Background: var(--color-background-secondary)
- Header: "Week streak" (11px, uppercase, wide letter-spacing)
- Circle: 110px diameter, #fbbf24 (amber), 2px border (#f59e0b darker amber)
- Number: "0" centered (48px, bold, white)
- Subtext: "Weeks in a row hitting your goals" (12px, gray-600)
- Spacing: 1.5rem above circle, 1.25rem below

## Layout
- Left/Right sections split with 0.5px divider
- Left = flex-1, Right = flex 0 0 220px
- Total padding: 2rem on all sections
- Use Tailwind classes where possible

## Data
```javascript
{
  focusMinutes: 51,
  hackerGoal: 800,
  personalGoal: 780,
  streak: 0
}
```

## Key Design Principles
- Hacker Goal is the hero—larger, bolder, more vibrant
- Personal Goal is secondary—smaller, muted, subtle
- Visual hierarchy strongly favors left section over right
- Streak circle has border for definition
- Tight, professional design—no excess whitespace

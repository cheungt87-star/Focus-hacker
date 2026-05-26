# Week Progress Component - Design Spec

Build a week progress tracking component with the following layout and styling:

## Layout
- **Left section (60%)**: Vertical stack of two goal trackers
- **Right section (40%)**: Centered week streak indicator with circle
- **Divider**: Subtle 0.5px border between sections

## Left Section: Goals
- Header: "Current week progress" (12px, uppercase, gray-500)
- For each goal:
  - Goal name on left, metric on right
  - Metric format: **51** (20px bold) + "of 800 min" (12px secondary)
  - Progress bar: 6px height, gray-100 background, colored fill
  - Completion percentage below bar (12px, gray-400)
- Goal colors: Blue (#3b82f6) and Purple (#8b5cf6)
- Spacing between goals: 1.75rem
- Padding: 2rem

## Right Section: Streak
- Header: "Week streak" (11px, uppercase, wide letter-spacing)
- Circle: 110px diameter, amber-400 (#fbbf24)
- Number: "0" centered in circle (48px, bold, white)
- Subtext below: "Weeks in a row hitting your goals" (12px, gray-600)
- Subtle background gradient (optional: can be solid)
- Padding: 2rem

## Styling Notes
- Tight, clean design—no excessive padding or whitespace
- Use Tailwind classes where possible
- Make it responsive if needed
- Keep the overall visual weight balanced between sections

## Data to Inject
```javascript
{
  goals: [
    { name: 'Hacker Goal', current: 51, target: 800, unit: 'min', percentage: 6, color: '#3b82f6' },
    { name: 'Personal Goal', current: 51, target: 780, unit: 'min', percentage: 7, color: '#8b5cf6' }
  ],
  streak: 0
}
```

# Project Name: FocusHacker
**Status:** Initial Draft
**Tech Stack:** Swift, SwiftUI, macOS 13 Ventura+, Network Extension Framework

---

## 1. Project Overview
- **Purpose:** A native Mac app that runs structured Pomodoro focus sessions, blocks distracting apps and websites during focus periods, and rewards consistent use with XP and level progression.
- **Core Value:** One app that blocks, times, and rewards focus — replacing the need to stitch together separate timers, blockers, and habit trackers.
- **Target Audience:** Mac users who struggle with digital distraction and want a structured, gamified system to build sustainable focus habits.

---

## 2. Technical Roadmap & Constraints
- **Platform:** macOS 13 Ventura minimum
- **Framework:** SwiftUI
- **State Management:** @Observable / @StateObject (SwiftUI native patterns)
- **App/Site Blocking:** Apple Network Extension framework (ContentFilterProvider)
- **Data/Backend:** Local storage only — UserDefaults for settings and session config, SwiftData for XP, level, and streak history
- **Audio:** AVFoundation for sound playback
- **Notifications:** UserNotifications framework + custom SwiftUI overlay for countdown splash
- **Monetisation:** StoreKit 2 — 7-day free trial, $14.99 one-time lifetime purchase
- **Iconography:** SF Symbols (native macOS standard)
- **App presence:** Menubar (quick access) + full window (settings and stats)
- **No cloud sync, no social or leaderboard features**

---

## 3. Core Features (MVP)

- [ ] **Feature 1: Pomodoro Timer**
  - [ ] Configurable focus duration (default: 25 mins)
  - [ ] Configurable rest duration (default: 5 mins)
  - [ ] Configurable number of rounds per session
  - [ ] Configurable long rest duration between rounds
  - [ ] Session start / pause / end controls
  - [ ] Ending a session early forfeits all XP accumulated in that session
  - [ ] Persistent timer state across app backgrounding

- [ ] **Feature 2: App & Website Blocker**
  - [ ] User-defined blocklist of apps and URLs
  - [ ] Blocklist enforced automatically when a focus period begins (via Network Extension)
  - [ ] Blocklist lifted automatically during rest periods and when session ends
  - [ ] Graceful handling of Network Extension permission prompts on first launch

- [ ] **Feature 3: Gamification**
  - [ ] XP awarded = number of focus minutes completed in a fully finished session
  - [ ] XP accumulates toward level thresholds (see curve below)
  - [ ] Level title and total XP displayed prominently in app
  - [ ] Daily streak counter — increments when at least one session is fully completed per calendar day
  - [ ] Streak tolerates up to 2 consecutive missed days before resetting
  - [ ] Session history log stored locally

  **XP Level Curve:**

  | Level | Title        | XP Required |
  |-------|-------------|-------------|
  | 1     | Rookie       | 0           |
  | 2     | Focused      | 100         |
  | 3     | Grinder      | 300         |
  | 4     | Deep Worker  | 700         |
  | 5     | Flow State   | 1,500       |
  | 6     | Obsessed     | 3,000       |
  | 7     | Legendary    | 6,000       |

  *At 25 XP per session, a user doing 3 sessions/day reaches Level 4 in ~10 days and Level 7 in ~80 days.*

- [x] **Feature 4: Notifications & Audio**
  - [x] 5-second countdown splash screen before each interval transition
  - [x] Audio prompt at each transition (e.g. "Time to work, Let's Focus!", "It's time to have a short break!. Take a rest!")
  - [x] Multiple free sound packs selectable in settings (all included with app, no paywalled packs)

- [ ] **Feature 5: Onboarding & Settings**
  - [ ] First-launch onboarding flow explaining core features and requesting Network Extension permission
  - [ ] Settings screen: timer defaults, blocklist management, sound pack selection
  - [x] StoreKit 2 trial gate — full access for 7 days, $14.99 one-time paywall on day 8

---

## 4. UI/UX Requirements
- **Platform conventions:** Follow macOS HIG. Native feel is the priority — no web-app aesthetic.
- **Menubar icon:** Shows current session state (idle / focus / rest) at a glance. Click to open popover with timer controls.
- **Full window:** Settings, stats, level progress, session history.
- **Timer display:** Large, prominent countdown. Warm/intense colour during focus, cool/calm colour during rest.
- **Splash screen:** Full-screen overlay with animated 5-second countdown before each interval transition.
- **Feedback:** Audio + visual cue at every state transition. No silent failures.
- **Design tone:** Focused, minimal, clean. Gamification elements (XP bar, level, streak) visible but not cluttered.

---

## 5. Development Rules for Cursor (Important!)
- **Always** use SwiftUI views and Swift concurrency (async/await, actors) — no legacy UIKit or AppKit patterns unless unavoidable.
- **Prefer** descriptive variable and function names over abbreviations.
- **Verify** that any Network Extension changes are tested on a real device — the simulator does not support Network Extension.
- **Don't** add third-party Swift packages without asking first. Prefer Apple-native frameworks throughout.
- **Consult** `@requirements.md` before starting any new feature.
- **Separate** concerns clearly: timer logic, blocking logic, and gamification logic must each live in their own model/service files — never inline in views.
- **Test** StoreKit flow using StoreKit Configuration files in Xcode — do not hardcode trial logic.

# FocusHacker — Data Schema

**Source:** `requirements.md`, `GAMIFICATION_SPEC.md` (gamification supersedes older XP level tables in requirements)
**Tech Stack:** SwiftData · UserDefaults · StoreKit 2
**Sync:** Local only — no iCloud, no cloud backend

---

## 1. SwiftData Models

### 1.1 `Session`

Represents one focus timer run (completed or ended early).

```swift
@Model
final class Session {
    var createdAt: Date
    var focusDurationMinutes: Int
    var roundsCompleted: Int
    var xpAwarded: Int
    var startedAt: Date?
    var endedAt: Date?
    var configuredRounds: Int?
    var didComplete: Bool?
    var totalFocusMinutes: Int?
    var sessionUUID: UUID?
    var naturallyConcluded: Bool?   // true = full completion (1.5× XP)
}
```

**XP:** `xpAwarded = round(minutes × 1 × (1.5 if naturallyConcluded else 1.0))`. Early ends can earn partial XP at 1×.

---

### 1.2 `XPRecord`

Immutable ledger entry per session award.

```swift
@Model
final class XPRecord {
    var xpAmount: Int
    var createdAt: Date
    var focusMinutesContributing: Int?
    var naturallyConcluded: Bool?
    var session: Session?
}
```

**Lifetime XP:** `SUM(XPRecord.xpAmount)` → badge level via `FocusBadgeProgression` (10 tiers, 1k–184k XP).

---

### 1.3 `StreakRecord`

Legacy daily-streak entity (retained for migration; weekly streaks use `PlayerProgress`).

---

### 1.4 `PlayerProgress`

Single-row weekly target evaluation state.

```swift
@Model
final class PlayerProgress {
    var lastEvaluatedWeekStart: Date?          // Monday 00:00 local
    var firstActivityWeekStart: Date?
    var defaultTargetStreak: Int
    var personalTargetStreak: Int
    var longestDefaultTargetStreak: Int
    var longestPersonalTargetStreak: Int
    var personalTargetMinutesAtLastEvaluation: Int?
}
```

**Weekly targets:** Default 800 min/week; personal target from UserDefaults. Streaks increment on closed weeks that hit target (pro-rata first partial week can hit without streak credit).

---

## 2. UserDefaults Keys

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `settings.gamification.personalWeeklyMinutesTarget` | `Int` | `600` | Personal weekly minutes goal |
| `settings.gamification.personalTargetLastModified` | `Date?` | `nil` | Set when personal target changes (resets personal streak) |
| `settings.gamification.xpBackfillCompleted` | `Bool` | `false` | One-time XP formula migration |
| `settings.gamification.weeklyXPGoalXP` | `Int` | `1000` | Legacy; deprecated in UI |

(Timer, blocker, audio, and shell keys unchanged — see prior schema sections in git history.)

---

## 3. Schema Versioning

| Version | Changes |
|---------|---------|
| v2 | Initial `Session`, `XPRecord`, `StreakRecord`, `PlayerProgress` |
| v3 | `naturallyConcluded` on Session/XPRecord; `PlayerProgress` weekly streak fields |

Use `FocusHackerMigrationPlan` lightweight migration v2 → v3.

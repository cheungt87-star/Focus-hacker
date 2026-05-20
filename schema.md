# FocusHacker — Data Schema

**Source:** `requirements.md`, `Userstories.md`
**Tech Stack:** SwiftData · UserDefaults · StoreKit 2
**Sync:** Local only — no iCloud, no cloud backend

---

## 1. SwiftData Models

### 1.1 `Session`

Represents one completed or terminated Pomodoro session.

```swift
@Model
final class Session {
    var id: UUID                    // Primary key
    var startedAt: Date             // Wall-clock start time (user local timezone)
    var endedAt: Date               // Wall-clock end time
    var focusDurationMinutes: Int   // Configured focus duration per round (mins)
    var shortRestMinutes: Int       // Configured short rest duration (mins)
    var longRestMinutes: Int        // Configured long rest duration (mins)
    var totalRounds: Int            // Total rounds configured for this session
    var completedRounds: Int        // Rounds actually finished (< totalRounds if ended early)
    var isCompleted: Bool           // true only if all rounds finished without early termination
    var xpEarned: Int               // 0 if ended early; = completedRounds × focusDurationMinutes otherwise
}
```

**Constraints:**
- `xpEarned` must be 0 when `isCompleted == false`
- `xpEarned = completedRounds × focusDurationMinutes` when `isCompleted == true`
- `completedRounds ≤ totalRounds` always
- Retain indefinitely (no auto-expiry); UI filters to last 90 days for display

**Indexes:** `startedAt` (DESC) — for history sorted newest-first

---

### 1.2 `XPRecord`

Immutable ledger entry written once per completed session. Drives level calculation.

```swift
@Model
final class XPRecord {
    var id: UUID                    // Primary key
    var sessionId: UUID             // Foreign key → Session.id
    var awardedAt: Date             // Timestamp of award (= session endedAt)
    var amount: Int                 // XP awarded (always > 0)
}
```

**Constraints:**
- One `XPRecord` per completed `Session` only (`isCompleted == true`)
- `amount > 0` always (no penalty records)
- `sessionId` is a soft reference — `Session` deletion does not cascade-delete `XPRecord`

**Derived value — Total XP:**
```
totalXP = SUM(XPRecord.amount)
```

**Derived value — Current Level:**

| Level | Title       | Min XP |
|-------|-------------|--------|
| 1     | Rookie      | 0      |
| 2     | Focused     | 100    |
| 3     | Grinder     | 300    |
| 4     | Deep Worker | 700    |
| 5     | Flow State  | 1,500  |
| 6     | Obsessed    | 3,000  |
| 7     | Legendary   | 6,000  |

Level is computed at runtime from `totalXP` — not stored.

---

### 1.3 `StreakRecord`

One record per calendar day on which at least one session was completed.

```swift
@Model
final class StreakRecord {
    var id: UUID                    // Primary key
    var calendarDate: Date          // Normalized to start-of-day, user local timezone
    var sessionsCompleted: Int      // Number of completed sessions on this day (≥ 1)
}
```

**Constraints:**
- One record per calendar day — upsert on completion, never insert duplicates
- `sessionsCompleted ≥ 1` always

**Derived value — Current Streak:**

```
Streak rules:
  - Sorted list of StreakRecord.calendarDate DESC
  - Walk backwards from today
  - Streak count = consecutive days found, allowing up to 2 missed days between entries
  - Reset to 0 on 3rd consecutive missed calendar day
```

Streak count is computed at runtime — not stored.

---

## 2. UserDefaults Keys

All settings keys use a `focushacker.` namespace prefix.

### 2.1 Timer Settings

| Key | Type | Default | Range | Description |
|-----|------|---------|-------|-------------|
| `focushacker.focusDurationMinutes` | `Int` | `25` | 1–120 | Focus interval length |
| `focushacker.shortRestMinutes` | `Int` | `5` | 1–30 | Short rest interval length |
| `focushacker.longRestMinutes` | `Int` | `15` | 1–60 | Long rest interval length |
| `focushacker.roundsPerSession` | `Int` | `4` | 1–99 | Rounds before session ends |

### 2.2 Blocker Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `focushacker.blockedBundleIDs` | `[String]` | `[]` | macOS app bundle IDs to block |
| `focushacker.blockedDomains` | `[String]` | `[]` | Domains/URLs to block (e.g. `twitter.com`, `*.reddit.com`) |

### 2.3 Audio & Notification Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `focushacker.selectedSoundPack` | `String` | `"voice-prompts"` | Identifier of active sound pack |
| `focushacker.audioMuted` | `Bool` | `false` | Global audio mute toggle |

### 2.4 App Shell Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `focushacker.lastSelectedWindowSection` | `String` | `"timer"` | Restores sidebar selection across launches |
| `focushacker.showInDock` | `Bool` | `false` | Controls Dock icon visibility |

### 2.5 Onboarding & Trial

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `focushacker.onboardingCompleted` | `Bool` | `false` | Guards first-launch onboarding gate |
| `focushacker.trialStartDate` | `Date?` | `nil` | Set once on first launch; nil until first run |
| `focushacker.networkExtensionPermissionGranted` | `Bool` | `false` | Cached permission state (re-verified at launch) |

---

## 3. StoreKit 2 — Purchase State

Purchase entitlement is managed entirely by StoreKit 2. **Do not persist purchase state in UserDefaults.**

| Product ID | Type | Price | Description |
|------------|------|-------|-------------|
| `com.focushacker.lifetime` | Non-consumable | $14.99 | Lifetime access — one-time purchase |

**Entitlement check at runtime:**
```swift
// Pseudocode — not stored, always re-verified
let hasAccess: Bool = isInTrial || hasLifetimePurchase
```

**Trial gate logic:**
```
trialStartDate = UserDefaults["focushacker.trialStartDate"]
trialActive    = Calendar.current.dateComponents([.day], from: trialStartDate, to: .now).day! < 7
hasLifetime    = StoreKit.currentEntitlements contains "com.focushacker.lifetime"
hasAccess      = trialActive || hasLifetime
```

---

## 4. Transient State (In-Memory Only)

These values live in actors/services and are never persisted.

| Property | Type | Owner | Description |
|----------|------|-------|-------------|
| `sessionState` | `enum SessionState` | `TimerService` | `.idle / .focus / .rest / .paused` |
| `currentRound` | `Int` | `TimerService` | Round currently in progress |
| `remainingSeconds` | `Int` | `TimerService` | Seconds left in current interval |
| `pendingSessionXP` | `Int` | `TimerService` | XP accumulating during session; zeroed on early end |
| `blocklistActive` | `Bool` | `BlockerService` | Whether Network Extension filter is currently enforced |

---

## 5. Schema Versioning

| Version | Changes |
|---------|---------|
| v1 | Initial schema — `Session`, `XPRecord`, `StreakRecord` |

Use SwiftData `VersionedSchema` + `MigrationPlan` for all future schema changes. Migrations must be backward-compatible or provide an explicit migration step. Never drop data without a user-visible warning.

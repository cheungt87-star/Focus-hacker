# Contributing to FocusHacker

## EPIC 1 Coding Rules
- Use Swift `async/await` for asynchronous work. Do not add callback-style completion handlers.
- Place mutable shared state behind `actor` boundaries (timer, blocker, gamification state stores).
- Use descriptive names for variables, functions, and types. Avoid single-letter abbreviations.
- Keep business logic in service files under `Services/`; SwiftUI views only render state and forward intents.
- Do not add third-party Swift packages without explicit approval.

## Service Boundaries
- `Services/Timer`: session lifecycle and timing responsibilities.
- `Services/Blocker`: blocker activation/deactivation boundary with Network Extension.
- `Services/Gamification`: XP, level, streak progression services.
- `Services/Persistence`: `UserDefaults` and SwiftData stores/factories.

## PR Definition of Done
- [ ] Builds succeed for app and extension targets.
- [ ] XCTest smoke tests pass for app and extension targets.
- [ ] Persistence tests pass using in-memory SwiftData.
- [ ] Lint passes (`swiftlint`).
- [ ] New code follows token usage (no hardcoded UI colors/fonts in views).
- [ ] Added or updated docs for any architecture boundary changes.

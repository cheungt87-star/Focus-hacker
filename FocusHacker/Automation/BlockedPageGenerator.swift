import Foundation

/// Stage 1: serves the static bundled `blocked.html`. Future: rewrite with focus end time.
enum BlockedPageGenerator {
    static func resolvedBlockedPageURLString() -> String? {
        BlockedPageURL.fileURLStringForAppleScript()
    }
}

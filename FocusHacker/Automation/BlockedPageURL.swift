import Foundation

enum BlockedPageURL {
    static func bundledFileURL() -> URL? {
        Bundle.main.url(forResource: "blocked", withExtension: "html")
    }

    static func fileURLStringForAppleScript() -> String? {
        bundledFileURL()?.absoluteString
    }

    static func isBlockedPageURL(_ url: URL) -> Bool {
        guard let blocked = bundledFileURL() else {
            return false
        }
        return url.absoluteString.hasPrefix(blocked.absoluteString)
            || url.path == blocked.path
    }
}
